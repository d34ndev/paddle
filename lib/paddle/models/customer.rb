module Paddle
  class Customer < Object
    class << self
      def list(**params)
        response = Client.get_request("customers", params: params)
        Collection.from_response(response, type: Customer)
      end

      def create(email:, **params)
        attrs = { email: email.gsub(/\s+/, "") }
        response = Client.post_request("customers", body: attrs.merge(params))
        Customer.new(response.body["data"])
      end

      def retrieve(id:)
        response = Client.get_request("customers/#{id}")
        Customer.new(response.body["data"])
      end

      def update(id:, **params)
        response = Client.patch_request("customers/#{id}", body: params)
        Customer.new(response.body["data"])
      end

      def credit_balances(id:, **params)
        response = Client.get_request("customers/#{id}/credit-balances", params: params)
        Collection.from_response(response, type: CreditBalance)
      end

      # Returns only the first credit balance. Customers have a balance per currency,
      # so use credit_balances to get all of them.
      def credit(id:)
        credit_balances(id: id).first
      end

      def auth_token(id:)
        response = Client.post_request("customers/#{id}/auth-token", body: "")
        CustomerAuthToken.new(response.body["data"])
      end
    end
  end
end
