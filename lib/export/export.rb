module Export

  class UnsupportedExportSource   < RuntimeError; end
  class FormatInvalidError        < RuntimeError; end
  class FilenameMissingError      < RuntimeError; end
  class ExportInProgressError     < RuntimeError; end

  def self.current_schema_version
    ActiveRecord::Migrator.current_version.to_s
  end

  def self.models_included_in_export
    @models_included_in_export ||= begin
      Rails.application.eager_load! # So that all models get loaded now
      ActiveRecord::Base.descendants - [ActiveRecord::SchemaMigration]
    end
  end

  def self.export_running_key
    'exporter_is_running'
  end

  def self.mark_as_running!
    $redis.set(export_running_key, '1')
  end

  def self.is_running?
    !!$redis.get(export_running_key)
  end

  def self.mark_as_not_running!
    $redis.del(export_running_key)
  end

  def self.start!(user_id)
    child = fork do
      begin
        Export.establish_app
        Jobs::Exporter.new.execute(user_id: user_id)
      ensure
        exit!(0)
      end
    end

    Process.detach(child)

    child
  end

  private

  def self.establish_app
    ActiveRecord::Base.connection_handler.clear_active_connections!
    ActiveRecord::Base.establish_connection
    $redis.client.reconnect
    Rails.cache.reconnect
    MessageBus.after_fork

    Signal.trap("HUP") do
      exit!(0)
    end

    # TODO? redirect STDIN/STDOUT/STDERR to /dev/null
  end

end
