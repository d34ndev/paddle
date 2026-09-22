module Paddle
  class ErrorGenerator < StandardError
    attr_reader :http_status_code
    attr_reader :paddle_error_code
    attr_reader :paddle_error_message
    attr_reader :paddle_errors
    attr_reader :documentation_url
    attr_reader :request_id

    def initialize(response_body, http_status_code)
      # Non-JSON responses (e.g. an HTML page from a gateway) have no Paddle error details
      @response_body = response_body.is_a?(Hash) ? response_body : {}
      @http_status_code = http_status_code
      set_paddle_error_values
      super(build_message)
    end

    private

    def set_paddle_error_values
      @paddle_error_code = @response_body.dig("error", "code")
      @paddle_error_message = @response_body.dig("error", "detail")
      @paddle_errors = @response_body.dig("error", "errors") || []
      @documentation_url = @response_body.dig("error", "documentation_url")
      @request_id = @response_body.dig("meta", "request_id")
    end

    def error_message
      @paddle_error_message || @paddle_error_code || "An unknown error occurred."
    end

    def build_message
      base_message = if paddle_error_code.nil?
        "Error #{@http_status_code}: #{error_message}"
      else
        "Error #{@http_status_code}: #{error_message} '#{paddle_error_code}'"
      end

      # Add detailed field errors if present
      if @paddle_errors && !@paddle_errors.empty?
        field_errors = @paddle_errors.map do |err|
          "  - #{err['field']}: #{err['message']}"
        end.join("\n")
        base_message += "\nField errors:\n#{field_errors}"
      end

      # Add documentation URL if present
      if @documentation_url
        base_message += "\nDocumentation: #{@documentation_url}"
      end

      # Add request ID if present (useful for support)
      if @request_id
        base_message += "\nRequest ID: #{@request_id}"
      end

      base_message
    end
  end

  module Errors
    class BadRequestError < ErrorGenerator
      private

      def error_message
        # Use the detailed Paddle error message if available, otherwise fall back to generic message
        @paddle_error_message || "Your request was malformed."
      end
    end

    class AuthenticationMissingError < ErrorGenerator
      private

      def error_message
        "You did not supply valid authentication credentials."
      end
    end

    class ForbiddenError < ErrorGenerator
      private

      def error_message
        "You are not allowed to perform that action."
      end
    end

    class EntityNotFoundError < ErrorGenerator
      private

      def error_message
        "No results were found for your request."
      end
    end

    class ConflictError < ErrorGenerator
      private

      def error_message
        "Your request was a conflict."
      end
    end

    class TooManyRequestsError < ErrorGenerator
      private

      def error_message
        "Your request exceeded the API rate limit."
      end
    end

    class InternalError < ErrorGenerator
      private

      def error_message
        "We were unable to perform the request due to server-side problems."
      end
    end

    class ServiceUnavailableError < ErrorGenerator
      private

      def error_message
        "You have been rate limited for sending more than 20 requests per second."
      end
    end

    class NotImplementedError < ErrorGenerator
      private

      def error_message
        "This resource has not been implemented."
      end
    end
  end

  class ErrorFactory
    HTTP_ERROR_MAP = {
      400 => Errors::BadRequestError,
      401 => Errors::AuthenticationMissingError,
      403 => Errors::ForbiddenError,
      404 => Errors::EntityNotFoundError,
      409 => Errors::ConflictError,
      429 => Errors::TooManyRequestsError,
      500 => Errors::InternalError,
      503 => Errors::ServiceUnavailableError,
      501 => Errors::NotImplementedError
    }.freeze

    def self.create(response_body, http_status_code)
      status = http_status_code
      error_class = HTTP_ERROR_MAP[status] || ErrorGenerator
      error_class.new(response_body, http_status_code) if error_class
    end
  end
end
