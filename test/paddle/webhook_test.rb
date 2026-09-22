require "test_helper"

class WebhookTest < Minitest::Test
  SECRET = "pdl_ntfset_01h7dvz5d8y0q1w0d9x7wbe4b5_abc123"
  PAYLOAD = '{"event_id":"evt_01h8441jx8x5hwrbd3sb4bhvj6","event_type":"transaction.completed","occurred_at":"2022-12-20T16:12:57.311Z","notification_id":"ntf_01h8441jz6c8qrsbc40kab6pdh","data":{"id":"txn_01h8441g2ne7yvkv1hvf2ey0v5","status":"completed"}}'

  # Computed independently with Python's hmac module for ts=1671552777
  KNOWN_SIGNATURE = "ts=1671552777;h1=6e5a6d33f22645711d79215ef46ee413e4e2277853f96d095f5d8eed7135867e"

  def sign(payload, timestamp: Time.now.to_i, secret: SECRET)
    "ts=#{timestamp};h1=#{OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}:#{payload}")}"
  end

  def assert_verification_error(message, **args)
    error = assert_raises(Paddle::Webhook::SignatureVerificationError) do
      Paddle::Webhook.verify!(payload: PAYLOAD, secret: SECRET, **args)
    end
    assert_match message, error.message
  end

  def test_known_signature
    assert Paddle::Webhook.verify!(payload: PAYLOAD, signature: KNOWN_SIGNATURE, secret: SECRET, tolerance: nil)
  end

  def test_valid_signature_within_tolerance
    assert Paddle::Webhook.verify!(payload: PAYLOAD, signature: sign(PAYLOAD), secret: SECRET)
  end

  def test_signature_for_a_different_payload
    tampered = PAYLOAD.sub("completed", "canceled")

    assert_verification_error(/doesn't match/, signature: sign(tampered))
  end

  def test_signature_after_the_body_is_reformatted
    reformatted = JSON.generate(JSON.parse(PAYLOAD)).sub(":", ": ")

    assert_verification_error(/doesn't match/, signature: sign(reformatted))
  end

  def test_signature_with_the_wrong_secret
    assert_verification_error(/doesn't match/, signature: sign(PAYLOAD, secret: "pdl_ntfset_wrong"))
  end

  def test_timestamp_too_old
    assert_verification_error(/tolerance of 5 seconds/, signature: sign(PAYLOAD, timestamp: Time.now.to_i - 10))
  end

  def test_timestamp_too_far_in_the_future
    assert_verification_error(/tolerance/, signature: sign(PAYLOAD, timestamp: Time.now.to_i + 10))
  end

  def test_custom_tolerance
    signature = sign(PAYLOAD, timestamp: Time.now.to_i - 10)

    assert Paddle::Webhook.verify!(payload: PAYLOAD, signature: signature, secret: SECRET, tolerance: 60)
  end

  def test_known_signature_fails_with_default_tolerance
    assert_verification_error(/tolerance/, signature: KNOWN_SIGNATURE)
  end

  def test_multiple_h1_signatures_during_secret_rotation
    timestamp = Time.now.to_i
    valid = sign(PAYLOAD, timestamp: timestamp).split(";h1=").last
    signature = "ts=#{timestamp};h1=#{"0" * 64};h1=#{valid}"

    assert Paddle::Webhook.verify!(payload: PAYLOAD, signature: signature, secret: SECRET)
  end

  def test_malformed_headers
    [ "h1=abc", "ts=1671552777", "ts=abc;h1=abc", "ts=;h1=abc", "garbage" ].each do |signature|
      assert_verification_error(/malformed/, signature: signature)
    end
  end

  def test_missing_header
    assert_verification_error(/Missing Paddle-Signature/, signature: nil)
    assert_verification_error(/Missing Paddle-Signature/, signature: "")
  end

  def test_missing_secret
    error = assert_raises(Paddle::Webhook::SignatureVerificationError) do
      Paddle::Webhook.verify!(payload: PAYLOAD, signature: sign(PAYLOAD), secret: nil)
    end
    assert_match(/Missing webhook secret/, error.message)
  end

  def test_valid?
    assert Paddle::Webhook.valid?(payload: PAYLOAD, signature: sign(PAYLOAD), secret: SECRET)
    refute Paddle::Webhook.valid?(payload: PAYLOAD, signature: sign(PAYLOAD, secret: "wrong"), secret: SECRET)
    refute Paddle::Webhook.valid?(payload: PAYLOAD, signature: nil, secret: SECRET)
  end

  def test_construct_event
    event = Paddle::Webhook.construct_event(payload: PAYLOAD, signature: sign(PAYLOAD), secret: SECRET)

    assert_equal Paddle::Event, event.class
    assert_equal "transaction.completed", event.event_type
    assert_equal "txn_01h8441g2ne7yvkv1hvf2ey0v5", event.data.id
  end

  def test_construct_event_with_invalid_signature
    assert_raises(Paddle::Webhook::SignatureVerificationError) do
      Paddle::Webhook.construct_event(payload: PAYLOAD, signature: sign(PAYLOAD, secret: "wrong"), secret: SECRET)
    end
  end

  def test_signature_verification_error_is_a_paddle_error
    assert_operator Paddle::Webhook::SignatureVerificationError, :<, Paddle::Error
  end
end
