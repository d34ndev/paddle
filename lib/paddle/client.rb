require "faraday"

module Paddle
  class Client
    @connections = {}
    @mutex = Mutex.new

    class << self
      # One connection is kept per base URL and set of connection options. The API key and
      # version are sent with each request, so config changes take effect straight away
      def connection
        config = Paddle.config
        key = [ config.url, config.connection_options.hash ]

        @mutex.synchronize do
          @connections[key] ||= create_connection(config)
        end
      end

      def get_request(url, params: {}, headers: {})
        # Paddle expects arrays as comma-separated lists, e.g. status=active,past_due
        params = params.transform_values { |value| value.is_a?(Array) ? value.join(",") : value }

        # skip_count is sent as a header rather than a query param
        headers = headers.merge("Skip-Count" => "true") if params.delete(:skip_count)

        handle_response(connection.get(url, params, request_headers(headers)))
      end

      def post_request(url, body: {}, headers: {})
        handle_response(connection.post(url, body, request_headers(headers)))
      end

      def patch_request(url, body:, headers: {})
        handle_response(connection.patch(url, body, request_headers(headers)))
      end

      def delete_request(url, headers: {})
        handle_response(connection.delete(url, nil, request_headers(headers)))
      end

      private

      def create_connection(config)
        Faraday.new(config.url, config.connection_options) do |conn|
          conn.headers = { "User-Agent" => "paddle/v#{VERSION} (github.com/deanpcmad/paddle)" }
          conn.request :json
          conn.response :json
        end
      end

      def request_headers(headers)
        config = Paddle.config

        {
          "Authorization" => "Bearer #{config.api_key}",
          "Paddle-Version" => config.version.to_s
        }.merge(headers)
      end

      def handle_response(response)
        return true if response.status == 204
        return response unless error?(response)

        raise_error(response)
      end

      def error?(response)
        !response.success? || (response.body.is_a?(Hash) && response.body.key?("error"))
      end

      def raise_error(response)
        error = Paddle::ErrorFactory.create(response.body, response.status)
        raise error if error
      end
    end
  end
end
