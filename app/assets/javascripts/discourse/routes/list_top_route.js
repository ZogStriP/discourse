Discourse.ListTopRoute = Discourse.Route.extend({

  activate: function() {
    // will mark the "top" navigation item as selected
    this.controllerFor('list').set('filterMode', 'top');
  },

  model: function() {
    return Discourse.TopList.find();
  },

  renderTemplate: function() {
    this.render('top', { into: 'list', outlet: 'listView' });
  }

});
