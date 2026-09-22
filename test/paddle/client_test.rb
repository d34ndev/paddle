require "test_helper"

class ClientTest < Minitest::Test
  def test_bad_gateway_with_html_body
    error = assert_raises(Paddle::ErrorGenerator) do
      Paddle::Product.retrieve(id: "pro_01h7zcgmdc6tmwtjehp3sh7azf")
    end

    assert_equal 502, error.http_status_code
    assert_equal "Error 502: An unknown error occurred.", error.message
  end

  def test_gateway_timeout_with_empty_body
    error = assert_raises(Paddle::ErrorGenerator) do
      Paddle::Product.retrieve(id: "pro_01h7zcgmdc6tmwtjehp3sh7azf")
    end

    assert_equal 504, error.http_status_code
  end

  def test_unmapped_status_with_json_error
    error = assert_raises(Paddle::ErrorGenerator) do
      Paddle::Product.retrieve(id: "pro_01h7zcgmdc6tmwtjehp3sh7azf")
    end

    assert_equal 422, error.http_status_code
    assert_equal "invalid_field", error.paddle_error_code
    assert_equal "The request could not be processed.", error.paddle_error_message
  end

  def test_array_params_are_sent_comma_separated
    subscriptions = Paddle::Subscription.list(status: [ "active", "past_due" ], id: [ "sub_01", "sub_02" ])

    assert_equal [ "sub_01", "sub_02" ], subscriptions.map(&:id)
  end

  def test_array_include_on_retrieve_is_sent_comma_separated
    transaction = Paddle::Transaction.retrieve(id: "txn_01", extra: [ "address", "customer" ])

    assert_equal "txn_01", transaction.id
  end

  AUTH_AND_VERSION = ->(r1, r2) {
    r1.headers["Authorization"] == r2.headers["Authorization"] && r1.headers["Paddle-Version"] == r2.headers["Paddle-Version"]
  }

  def test_config_changes_after_the_first_request_take_effect
    VCR.use_cassette("test_client_config_changes", match_requests_on: [ :method, :uri, AUTH_AND_VERSION ]) do
      with_global_config(api_key: "pdl_sdbx_apikey_first", version: 1) do
        assert_equal "sandbox", Paddle::EventType.list.first.name

        Paddle.config.api_key = "pdl_live_apikey_second"
        Paddle.config.version = 2

        assert_equal "production", Paddle::EventType.list.first.name
      end
    end
  end

  def test_connection_is_reused
    assert_same Paddle::Client.connection, Paddle::Client.connection
  end

  def test_connection_per_environment
    sandbox = Paddle::Client.connection

    with_global_config(environment: :production) do
      production = Paddle::Client.connection

      refute_same sandbox, production
      assert_equal "https://api.paddle.com/", production.url_prefix.to_s
    end

    assert_same sandbox, Paddle::Client.connection
  end

  def test_connection_per_connection_options
    default = Paddle::Client.connection
    Paddle.config.connection_options = { request: { timeout: 3 } }

    refute_same default, Paddle::Client.connection
    assert_equal 3, Paddle::Client.connection.options.timeout
  ensure
    Paddle.config.connection_options = {}
  end

  def test_connection_is_shared_across_threads
    connections = 20.times.map { Thread.new { Paddle::Client.connection } }.map(&:value)

    assert_equal 1, connections.uniq(&:object_id).size
  end

  def test_connection_does_not_store_credentials
    refute Paddle::Client.connection.headers.key?("Authorization")
    refute Paddle::Client.connection.headers.key?("Paddle-Version")
  end
end
