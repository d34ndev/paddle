require "test_helper"

class WithConfigTest < Minitest::Test
  LIVE_KEY = "pdl_live_apikey_fake_live_key_for_tests"
  SANDBOX_KEY = "pdl_sdbx_apikey_fake_sandbox_key_for_tests"
  OTHER_SANDBOX_KEY = "pdl_sdbx_apikey_fake_other_sandbox_key"
  LEGACY_KEY = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8s9t0u1v2w3x4y5"

  def test_overrides_the_config_inside_the_block
    Paddle.with_config(api_key: OTHER_SANDBOX_KEY, version: 2) do
      assert_equal OTHER_SANDBOX_KEY, Paddle.config.api_key
      assert_equal 2, Paddle.config.version
    end

    refute_equal OTHER_SANDBOX_KEY, Paddle.config.api_key
    assert_equal 1, Paddle.config.version
  end

  def test_does_not_change_the_global_config
    global = Paddle.global_config

    Paddle.with_config(api_key: LIVE_KEY) do
      refute_same global, Paddle.config
    end

    assert_same global, Paddle.config
    assert_equal :sandbox, Paddle.config.environment
  end

  def test_restores_the_config_when_the_block_raises
    assert_raises(RuntimeError) do
      Paddle.with_config(api_key: LIVE_KEY) { raise "boom" }
    end

    assert_same Paddle.global_config, Paddle.config
  end

  def test_returns_the_block_value
    assert_equal 42, Paddle.with_config(version: 2) { 42 }
  end

  def test_nested_blocks
    Paddle.with_config(api_key: LIVE_KEY) do
      Paddle.with_config(version: 2) do
        assert_equal LIVE_KEY, Paddle.config.api_key
        assert_equal :production, Paddle.config.environment
        assert_equal 2, Paddle.config.version
      end

      assert_equal 1, Paddle.config.version
      assert_equal LIVE_KEY, Paddle.config.api_key
    end
  end

  def test_environment_is_detected_from_a_new_key
    Paddle.with_config(api_key: LIVE_KEY) do
      assert_equal :production, Paddle.config.environment
      assert_equal "https://api.paddle.com", Paddle.config.url
    end
  end

  def test_legacy_key_keeps_the_current_environment
    Paddle.with_config(api_key: LEGACY_KEY) do
      assert_equal :sandbox, Paddle.config.environment
    end
  end

  def test_explicit_environment
    Paddle.with_config(api_key: LEGACY_KEY, environment: :production) do
      assert_equal :production, Paddle.config.environment
    end
  end

  def test_mismatched_environment_raises
    error = assert_raises(ArgumentError) do
      Paddle.with_config(api_key: SANDBOX_KEY, environment: :production) { flunk "block should not run" }
    end

    assert_match(/sandbox environment/, error.message)
    assert_same Paddle.global_config, Paddle.config
  end

  def test_unknown_option_raises
    error = assert_raises(ArgumentError) { Paddle.with_config(api_kye: LIVE_KEY) { } }

    assert_equal "Unknown config options: api_kye", error.message
  end

  def test_configure_inside_the_block_changes_the_global_config
    Paddle.with_config(version: 2) do
      Paddle.configure { |config| assert_same Paddle.global_config, config }
    end
  end

  def test_threads_do_not_see_each_others_config
    keys = 10.times.map { |i| "pdl_sdbx_apikey_fake_thread_#{i}" }
    ready = Queue.new
    go = Queue.new

    threads = keys.map do |key|
      Thread.new do
        Paddle.with_config(api_key: key) do
          ready << true
          go.pop # wait until every thread is inside its block
          Paddle.config.api_key
        end
      end
    end

    keys.size.times { ready.pop }
    keys.size.times { go << true }

    assert_equal keys, threads.map(&:value)
  end

  def test_threads_started_inside_the_block_inherit_the_config
    Paddle.with_config(api_key: LIVE_KEY) do
      assert_equal LIVE_KEY, Thread.new { Paddle.config.api_key }.value
    end
  end

  def test_requests_use_the_config_from_the_block
    matcher = ->(r1, r2) { r1.headers["Authorization"] == r2.headers["Authorization"] }

    VCR.use_cassette("test_with_config_requests", match_requests_on: [ :method, :uri, matcher ]) do
      Paddle.with_config(api_key: LIVE_KEY) do
        assert_equal "production", Paddle::EventType.list.first.name
      end

      Paddle.with_config(api_key: OTHER_SANDBOX_KEY) do
        assert_equal "other sandbox", Paddle::EventType.list.first.name
      end
    end
  end
end
