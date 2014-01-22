/**
  Builds the routes for the admin section

  @method buildRoutes
  @for Discourse.AdminRoute
**/
Discourse.Route.buildRoutes(function() {
  this.resource('admin', function() {
    this.route('dashboard', { path: '/' });
    this.resource('adminSiteSettings', { path: '/site_settings' }, function() {
      this.resource('adminSiteSettingsCategory', { path: 'category/:category_id'} );
    });

    this.resource('adminSiteContents', { path: '/site_contents' }, function() {
      this.resource('adminSiteContentEdit', {path: '/:content_type'});
    });

    this.resource('adminEmail', { path: '/email'}, function() {
      this.route('logs');
      this.route('previewDigest', { path: '/preview-digest' });
    });

    this.route('customize');
    this.route('api');

    this.resource('adminReports', { path: '/reports/:type' });

    this.resource('adminFlags', { path: '/flags' }, function() {
      this.route('active');
      this.route('old');
    });

    this.resource('adminLogs', { path: '/logs' }, function() {
      this.route('staffActionLogs', { path: '/staff_action_logs' });
      this.route('screenedEmails', { path: '/screened_emails' });
      this.route('screenedIpAddresses', { path: '/screened_ip_addresses' });
      this.route('screenedUrls', { path: '/screened_urls' });
    });

    this.route('groups');

    this.resource('adminUsers', { path: '/users' }, function() {
      this.resource('adminUser', { path: '/:username' }, function() {
        this.route('leaderRequirements', { path: '/leader_requirements' });
      });
      this.resource('adminUsersList', { path: '/list' }, function() {
        _.each(['active', 'new', 'pending', 'admins', 'moderators', 'blocked', 'suspended',
                'newuser', 'basic', 'regular', 'leaders', 'elders'], function(x) {
          this.route(x, { path: '/' + x });
        }, this);
      });
    });

  });
});
