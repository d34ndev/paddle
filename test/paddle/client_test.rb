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
end
