/**
  Our data model for representing a backup

  @class Backup
  @extends Discourse.Model
  @namespace Discourse
  @module Discourse
**/
Discourse.Backup = Discourse.Model.extend({

  /**
    Destroy the current backup

    @method destroy
    @returns {Promise} a promise that resolves when the backup has been destroyed
  **/
  destroy: function() {
    return Discourse.ajax("/admin/backups/" + this.get("filename"), { type: "DELETE" });
  }

});

Discourse.Backup.reopenClass({

  /**
    Finds a list of backups

    @method find
    @returns {Promise} a promise that resolves to the array of {Discourse.Backup} backup
  **/
  find: function() {
    return Discourse.ajax("/admin/backups").then(function(data){
      return Discourse.Model.create({
        isBackupOrRestoreRunning: data.is_backup_or_restore_running,
        backups: data.backups.map(function (backup) { return Discourse.Backup.create(backup); })
      });
    });
  },

  /**
    Starts a backup

    @method start
    @returns {Promise} a promise that resolves to the {Discourse.Backup} backup
  **/
  start: function() {
    return Discourse.ajax("/admin/backups", { type: "POST" }).then(function(result) {
      if (!result.success) {
        bootbox.alert(result.message);
      }
    });
  },

  /**
    Cancels a backup

    @method cancel
    @returns {Promise} a promise that resolves to the {Discourse.Backup} backup
  **/
  cancel: function() {
    return Discourse.ajax("/admin/backups/cancel").then(function(result) {
      if (!result.success) {
        bootbox.alert(result.message);
      }
    });
  },

});
