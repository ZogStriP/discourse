require "sidekiq/pausable"

sidekiq_redis = { url: $redis.url, namespace: 'sidekiq' }

Sidekiq.configure_client do |config|
  config.redis = sidekiq_redis
end

Sidekiq.configure_server do |config|
  config.redis = sidekiq_redis
  # add our pausable middleware
  config.server_middleware do |chain|
    chain.add Sidekiq::Pausable
  end
end

Sidekiq.logger.level = Logger::WARN

# we only check for new jobs once every 5 seconds to cut down on cpu cost
Sidetiq.configure do |config|
  config.resolution = 5
end
