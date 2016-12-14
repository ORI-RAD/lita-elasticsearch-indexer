require "lita-elasticsearch-indexer"
require "lita/rspec"

# A compatibility mode is provided for older plugins upgrading from Lita 3. Since this plugin
# was generated with Lita 4, the compatibility mode should be left disabled.
Lita.version_3_compatibility_mode = false

Lita.configure do |config|
  config.redis[:host] = ENV['LITA_REDIS_HOST']
  # config.redis.port = 1234
end
