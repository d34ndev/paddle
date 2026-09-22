require "test_helper"

class ConfigurationTest < Minitest::Test
  def setup
    @saved_api_key = Paddle.config.api_key
    Paddle.config.api_key = "abc123"
  end

  def teardown
    Paddle.config.api_key = @saved_api_key
  end

  def test_api_key
    assert_equal "abc123", Paddle.config.api_key
  end

  def test_environment_should_default_to_production
    Paddle.config.environment = nil
    assert_equal Paddle.config.url, "https://api.paddle.com"
  end

  def test_production_environment
    Paddle.config.environment = :production
    assert_equal Paddle.config.url, "https://api.paddle.com"
  end

  def test_development_environment
    Paddle.config.environment = :development
    assert_equal Paddle.config.url, "https://sandbox-api.paddle.com"
  end

  def test_sandbox_environment
    Paddle.config.environment = :sandbox
    assert_equal Paddle.config.url, "https://sandbox-api.paddle.com"
  end

  def test_version
    Paddle.config.version = 2
    assert_equal 2, Paddle.config.version
  end

  def test_connection_options_defaults_to_empty_hash
    assert_equal({}, Paddle.config.connection_options)
  end

  def test_connection_options_passes_timeout_to_faraday
    Paddle.config.connection_options = { request: { timeout: 10, open_timeout: 5 } }

    conn = Paddle::Client.connection
    assert_equal 10, conn.options.timeout
    assert_equal 5, conn.options.open_timeout
  ensure
    reset_client_connection
  end

  def test_connection_options_passes_proxy_to_faraday
    Paddle.config.connection_options = { proxy: "http://localhost:8080" }

    conn = Paddle::Client.connection
    assert_equal "http://localhost:8080", conn.proxy.uri.to_s
  ensure
    reset_client_connection
  end

  LIVE_KEY = "pdl_live_apikey_fake_live_key_for_tests"
  SANDBOX_KEY = "pdl_sdbx_apikey_fake_sandbox_key_for_tests"
  LEGACY_KEY = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5"

  def test_sandbox_key_sets_sandbox_environment
    config = Paddle::Configuration.new
    config.api_key = SANDBOX_KEY

    assert_equal :sandbox, config.environment
    assert_equal "https://sandbox-api.paddle.com", config.url
  end

  def test_live_key_sets_production_environment
    config = Paddle::Configuration.new
    config.api_key = LIVE_KEY

    assert_equal :production, config.environment
    assert_equal "https://api.paddle.com", config.url
  end

  def test_legacy_key_defaults_to_production
    config = Paddle::Configuration.new
    config.api_key = LEGACY_KEY

    assert_equal :production, config.environment
  end

  def test_legacy_key_with_explicit_sandbox_environment
    config = Paddle::Configuration.new
    config.environment = :sandbox
    config.api_key = LEGACY_KEY

    assert_equal :sandbox, config.environment
  end

  def test_matching_explicit_environment_in_either_order
    config = Paddle::Configuration.new
    config.environment = :sandbox
    config.api_key = SANDBOX_KEY
    assert_equal :sandbox, config.environment

    config = Paddle::Configuration.new
    config.api_key = SANDBOX_KEY
    config.environment = :development
    assert_equal :development, config.environment

    config = Paddle::Configuration.new
    config.api_key = LIVE_KEY
    config.environment = :production
    assert_equal :production, config.environment
  end

  def test_sandbox_key_with_production_environment_raises
    config = Paddle::Configuration.new
    config.environment = :production

    error = assert_raises(ArgumentError) { config.api_key = SANDBOX_KEY }
    assert_equal "The API key is for the sandbox environment, but environment is set to :production", error.message
  end

  def test_production_environment_after_sandbox_key_raises
    config = Paddle::Configuration.new
    config.api_key = SANDBOX_KEY

    error = assert_raises(ArgumentError) { config.environment = :production }
    assert_equal "The API key is for the sandbox environment, but environment is set to :production", error.message
  end

  def test_live_key_with_sandbox_environment_raises
    config = Paddle::Configuration.new
    config.environment = :sandbox

    error = assert_raises(ArgumentError) { config.api_key = LIVE_KEY }
    assert_equal "The API key is for the production environment, but environment is set to :sandbox", error.message
    refute_includes error.message, LIVE_KEY
  end

  def test_resetting_environment_to_nil_uses_the_key
    config = Paddle::Configuration.new
    config.environment = :production
    config.environment = nil
    config.api_key = SANDBOX_KEY

    assert_equal :sandbox, config.environment
  end

  def test_changing_key_when_environment_was_detected
    config = Paddle::Configuration.new
    config.api_key = SANDBOX_KEY
    config.api_key = LIVE_KEY

    assert_equal :production, config.environment
  end

  private

  # Restore the sandbox config so VCR-backed tests in other files
  # always hit sandbox-api.paddle.com regardless of test ordering.
  def reset_client_connection
    Paddle.config.connection_options = {}
    Paddle.config.environment = :sandbox
  end
end
