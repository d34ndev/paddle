$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)
require "paddle"
require "minitest/autorun"
require "faraday"
require "json"
require "vcr"
require "dotenv/load"

VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :faraday

  config.filter_sensitive_data("<AUTHORIZATION>") { ENV["PADDLE_API_KEY_TEST"] }
end

Paddle.configure do |config|
  config.environment = :sandbox
  config.api_key = ENV["PADDLE_API_KEY_TEST"]
end

class Minitest::Test
  def setup
    VCR.insert_cassette(name)
  end

  def teardown
    VCR.eject_cassette
  end

  # Changes the global config for the block, then restores it
  def with_global_config(**attributes)
    config = Paddle.config
    saved = { api_key: config.api_key, environment: config.environment, version: config.version }

    config.environment = nil
    attributes.each { |name, value| config.public_send("#{name}=", value) }
    yield
  ensure
    config.environment = nil
    config.api_key = saved[:api_key]
    config.environment = saved[:environment]
    config.version = saved[:version]
  end
end
