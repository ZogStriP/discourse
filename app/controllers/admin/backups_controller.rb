class Admin::BackupsController < Admin::AdminController

  skip_before_filter :check_xhr, only: [:show]

  def index
    data = {
      backups: Backup.all,
      is_backup_or_restore_running: Export::is_running? || Import::is_running?
    }
    render_json_dump(data)
  end

  def create
    unless Export.is_running? || Import.is_running?
      pid = Export.start!(current_user.id)
      $redis.set("backup_or_restore_pid", pid)
      render json: success_json
    else
      operation = I18n.t("backup.operations." + (Export.is_running? ? "backup" : "restore"))
      message = I18n.t("backup.operation_already_running", { operation: operation })
      render json: failed_json.merge(message: message)
    end
  end

  def cancel
    if pid = $redis.get("backup_or_restore_pid")
      Process.kill "HUP", pid.to_i rescue nil
      Export.mark_as_not_running!
      Discourse.disable_readonly_mode
      Sidekiq.unpause!
    end
    render json: success_json
  end

  # download
  def show
    filename = params[:id]
    if backup = Backup[filename]
      send_file backup.path
    else
      render nothing: true, status: 404
    end
  end

  def destroy
    filename = params[:id]
    Backup.remove(filename)
    render nothing: true
  end

  def logs
    render nothing: true
  end

end
