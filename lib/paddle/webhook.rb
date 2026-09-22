require "json"
require "openssl"

module Paddle
  # Verifies the Paddle-Signature header sent with Billing webhooks.
  # https://developer.paddle.com/webhooks/signature-verification
  class Webhook
    class SignatureVerificationError < Paddle::Error; end

    # Paddle's SDKs reject webhooks with a timestamp more than 5 seconds from the current time
    DEFAULT_TOLERANCE = 5

    class << self
      # payload must be the raw request body, before any JSON parsing. secret is the
      # endpoint secret key for the notification destination. Pass tolerance: nil to
      # skip the timestamp check, e.g. when replaying a stored webhook in tests.
      def verify!(payload:, signature:, secret:, tolerance: DEFAULT_TOLERANCE)
        raise SignatureVerificationError, "Missing Paddle-Signature header" if signature.nil? || signature.empty?
        raise SignatureVerificationError, "Missing webhook secret" if secret.nil? || secret.empty?

        timestamp, signatures = parse_signature(signature)

        if tolerance && (Time.now.to_i - timestamp).abs > tolerance
          raise SignatureVerificationError, "Timestamp is outside the tolerance of #{tolerance} seconds"
        end

        expected = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}:#{payload}")

        # During secret rotation Paddle sends more than one h1, so any match is valid
        unless signatures.any? { |h1| OpenSSL.secure_compare(expected, h1) }
          raise SignatureVerificationError, "Signature doesn't match the payload"
        end

        true
      end

      def valid?(**args)
        verify!(**args)
      rescue SignatureVerificationError
        false
      end

      # Verifies the signature, then returns the payload as a Paddle::Event
      def construct_event(payload:, signature:, secret:, tolerance: DEFAULT_TOLERANCE)
        verify!(payload: payload, signature: signature, secret: secret, tolerance: tolerance)
        Event.new(JSON.parse(payload))
      end

      private

      # Parses "ts=1671552777;h1=eb4d0dc8..." into the timestamp and a list of h1 signatures
      def parse_signature(header)
        parts = header.split(";").map { |part| part.split("=", 2) }
        timestamp = parts.find { |key, _| key == "ts" }&.last
        signatures = parts.select { |key, _| key == "h1" }.map(&:last).compact

        unless timestamp&.match?(/\A\d+\z/) && signatures.any?
          raise SignatureVerificationError, "Paddle-Signature header is malformed"
        end

        [ timestamp.to_i, signatures ]
      end
    end
  end
end
