require_dependency "export/json_encoder"
require_dependency "export/export"
require_dependency "import/import"

module Jobs

  class Exporter < Jobs::Base

    sidekiq_options retry: false

    def execute(args)
      raise Import::ImportInProgressError if Import::is_running?
      raise Export::ExportInProgressError if Export::is_running?

      # make sure we have a user
      raise Discourse::InvalidParameters.new(:user_id) unless @user = if args[:user_id]
        User.where(id: args[:user_id].to_i).first
      end

      start_export

      sleep 200

      current_db = RailsMultisite::ConnectionManagement.current_db
      timestamp = Time.now.strftime("%Y-%m-%d-%H%M%S")
      filename = args[:filename] || File.join(Rails.root, "public", "backups", current_db, timestamp)

      @output_base_filename = File.absolute_path(filename)
      @output_base_filename = @output_base_filename[0...-3] if @output_base_filename[-3..-1] == ".gz"
      @output_base_filename = @output_base_filename[0...-4] if @output_base_filename[-4..-1] == ".tar"

      FileUtils.mkdir_p(File.dirname(@output_base_filename))

      log "Writing schema info..."
      @encoder.write_schema_info(source: "discourse", version: Export.current_schema_version)

      log "Exporting data..."
      ordered_models_for_export.each do |model|
        log "  - #{model.table_name}"
        column_info = model.columns
        order_col = column_info.map(&:name).find { |column| column == "id" } || order_columns_for(model)
        @encoder.write_table(model.table_name, column_info) do |num_rows_written|
          if order_col
            model.connection.select_rows("SELECT * FROM #{model.table_name} ORDER BY #{order_col} LIMIT #{batch_size} OFFSET #{num_rows_written}")
          else
            # Take the rows in the order the database returns them
            log "[WARNING]: no order by clause is being used for #{model.name} (#{model.table_name}). Please update Jobs::Exporter order_columns_for for #{model.name}."
            model.connection.select_rows("SELECT * FROM #{model.table_name} LIMIT #{batch_size} OFFSET #{num_rows_written}")
          end
        end
      end

      "#{@output_base_filename}.tar.gz"

    rescue => ex
      log ex.inspect
    ensure
      finish_export
    end

    def ordered_models_for_export
      Export.models_included_in_export
    end

    def order_columns_for(model)
      @order_columns_for_hash ||= {
        "CategorySearchData"    => "category_id",
        "PostReply"             => "post_id, reply_id",
        "PostSearchData"        => "post_id",
        "PostTiming"            => "topic_id, post_number, user_id",
        "SiteContent"           => "content_type",
        "TopicUser"             => "topic_id, user_id",
        "UserSearchData"        => "user_id",
        "UserStat"              => "user_id",
        "View"                  => "parent_id, parent_type, ip_address, viewed_at"
      }
      @order_columns_for_hash[model.name]
    end

    def batch_size
      1000
    end

    def start_export
      log "Starting export..."
      @encoder = Export::JsonEncoder.new
      log "Pausing sidekiq..."
      Sidekiq.pause!
      log "Waiting for sidekiq to finish running jobs..."
      wait_for_sidekiq
      log "Enabling readonly mode..."
      Export.mark_as_running!
      Discourse.enable_readonly_mode
      log "Export started!"
    end

    def wait_for_sidekiq
      # TODO: add a timeout (should not wait FOREVER)
      while (running = Sidekiq::Queue.all.map(&:size).sum) > 0
        log "  Waiting for #{running} jobs..."
        sleep 1
      end
    end

    def finish_export
      log "Finishing export..."
      @encoder.finish
      log "Creating tar file..."
      create_tar_file
      log "Removing temporary files..."
      @encoder.remove_tmp_directory("export")
    ensure
      log "Disabling readonly mode..."
      Export.mark_as_not_running!
      Discourse.disable_readonly_mode
      log "Unpausing sidekiq..."
      Sidekiq.unpause!
      log "Sending notifications..."
      notify_user
      log "Export finished!"
    end

    def create_tar_file
      filenames = @encoder.filenames
      tar_filename = "#{@output_base_filename}.tar"
      upload_directory = "uploads/" + RailsMultisite::ConnectionManagement.current_db

      log "Creating empty archive..."
      `tar --create --file #{tar_filename} --files-from /dev/null`

      log "Archiving data..."
      filenames.each do |filename|
        FileUtils.cd(File.dirname(filename)) do
          `tar --append --file #{tar_filename} #{File.basename(filename)}`
        end
      end

      log "Archiving uploads..."
      FileUtils.cd(File.join(Rails.root, "public")) do
        `tar --append --file #{tar_filename} #{upload_directory}`
      end

      log "Gzipping archive..."
      `gzip #{tar_filename}`
    end

    def notify_user
      # NOTE: will only notify if @user != Discourse.site_contact_user
      SystemMessage.create(@user, :export_succeeded)
    end

    def log(message)
      data = { timestamp: Time.now, message: message }
      MessageBus.publish("/admin/backups/logs", data, user_ids: [@user.id])
    end

  end

end
