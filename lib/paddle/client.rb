require "faraday"

module Paddle
  class Client
    class << self
      def connection
        @connection ||= create_connection
      end

      def get_request(url, params: {}, headers: {})
        handle_response(connection.get(url, params, headers))
      end

      def post_request(url, body: {}, headers: {})
        handle_response(connection.post(url, body, headers))
      end

      def patch_request(url, body:, headers: {})
        handle_response(connection.patch(url, body, headers))
      end

      def delete_request(url, headers: {})
        handle_response(connection.delete(url, headers))
      end

      private

      def create_connection
        Faraday.new(Paddle.config.url, Paddle.config.connection_options) do |conn|
          conn.request :authorization, :Bearer, Paddle.config.api_key
          conn.headers = default_headers
          conn.request :json
          conn.response :json
        end
      end

      def default_headers
        {
          "User-Agent" => "paddle/v#{VERSION} (github.com/deanpcmad/paddle)",
          "Paddle-Version" => Paddle.config.version.to_s
        }
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
