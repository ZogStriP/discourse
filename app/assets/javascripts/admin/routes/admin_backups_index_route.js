Discourse.AdminBackupsIndexRoute = Discourse.Route.extend({

  actions: {
    /**
      Starts a backup and redirect the user to the logs tab

      @method startBackup
    **/
    startBackup: function() {
      var self = this;
      bootbox.confirm(I18n.t("admin.backups.actions.backup.start.confirm"), I18n.t("no_value"), I18n.t("yes_value"), function(result) {
        if (result) {
          Discourse.Backup.start().then(function() {
            self.controllerFor("adminBackupsLogs").set("model", []);
            self.controllerFor("adminBackupsIndex").set("isBackupOrRestoreRunning", true);
            self.transitionTo("admin.backups.logs");
          });
        }
      });
    },

    /**
      Cancels a backup

      @method cancelBackup
    **/
    cancelBackup: function() {
      var self = this;
      bootbox.confirm(I18n.t("admin.backups.actions.backup.cancel.confirm"), I18n.t("no_value"), I18n.t("yes_value"), function(result) {
        if (result) {
          Discourse.Backup.cancel().then(function() {
            self.controllerFor("adminBackupsIndex").set("isBackupOrRestoreRunning", false);
            self.transitionTo("admin.backups");
          });
        }
      });
    }
  },

  setupController: function(controller) {
    Discourse.Backup.find().then(function (model) {
      controller.set("model", model);
    });
  },

});
