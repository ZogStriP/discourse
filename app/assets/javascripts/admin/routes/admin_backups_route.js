Discourse.AdminBackupsRoute = Discourse.Route.extend({

  CHANNEL: "/admin/backups/logs",

  activate: function() {
    var self = this;
    Discourse.MessageBus.subscribe(this.CHANNEL, function(data) {
      self.controllerFor("adminBackupsLogs").pushObject(Discourse.BackupLog.create(data));
    });
  },

  deactivate: function() {
    Discourse.MessageBus.unsubscribe(this.CHANNEL);
  }

});
