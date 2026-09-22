module Paddle
  module Classic
    class Client
      BASE_URL = "https://vendors.paddle.com/api"
      SANDBOX_BASE_URL = "https://sandbox-vendors.paddle.com/api"

      attr_reader :vendor_id, :vendor_auth_code, :sandbox, :adapter

      def initialize(vendor_id:, vendor_auth_code:, sandbox: false, adapter: Faraday.default_adapter, stubs: nil)
        @vendor_id = vendor_id
        @vendor_auth_code = vendor_auth_code
        @sandbox = sandbox
        @adapter = adapter

        # Test stubs for requests
        @stubs = stubs
      end

      def plans
        PlansResource.new(self)
      end

      def coupons
        CouponsResource.new(self)
      end

      def products
        ProductsResource.new(self)
      end

      def licenses
        LicensesResource.new(self)
      end

      def pay_links
        PayLinksResource.new(self)
      end

      def transactions
        TransactionsResource.new(self)
      end

      def payments
        PaymentsResource.new(self)
      end

      def users
        UsersResource.new(self)
      end

      def webhooks
        WebhooksResource.new(self)
      end

      def modifiers
        ModifiersResource.new(self)
      end

      def charges
        ChargesResource.new(self)
      end

      def url
        if sandbox == true
          SANDBOX_BASE_URL
        else
          BASE_URL
        end
      end

      def connection
        @connection ||= Faraday.new(url) do |conn|
          conn.headers = {
            "User-Agent" => "paddle/v#{VERSION} (github.com/d34ndev/paddle)"
          }

          conn.request :url_encoded

          conn.response :json, content_type: "application/json"

          conn.adapter adapter, @stubs
        end
      end
    end
  end
end
