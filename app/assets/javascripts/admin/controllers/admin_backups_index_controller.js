Discourse.AdminBackupsIndexController = Ember.ObjectController.extend({
  actions: {
    /**
      Destroys a backup

      @method destroyBackup
      @param {Discourse.Backup} the backup to destroy
    **/
    destroyBackup: function(backup) {
      var self = this;
      bootbox.confirm(I18n.t("admin.backups.actions.destroy.confirm"), I18n.t("no_value"), I18n.t("yes_value"), function(result) {
        if (result) {
          backup.destroy().then(function() {
            self.get("backups").removeObject(backup);
          });
        }
      });
    }
  }
});
