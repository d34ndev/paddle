module Paddle
  class Transaction < Object
    class << self
      def list(**params)
        response = Client.get_request("transactions", params: params)
        Collection.from_response(response, type: Transaction)
      end

      def create(items:, **params)
        attrs = { items: items }
        response = Client.post_request("transactions", body: attrs.merge(params))
        Transaction.new(response.body["data"])
      end

      def retrieve(id:, extra: nil)
        params = extra ? { include: extra } : {}
        response = Client.get_request("transactions/#{id}", params: params)
        Transaction.new(response.body["data"])
      end

      def update(id:, **params)
        response = Client.patch_request("transactions/#{id}", body: params)
        Transaction.new(response.body["data"])
      end

      # Revises customer, business and address details on a billed or completed transaction.
      # A transaction can only be revised once
      def revise(id:, **params)
        response = Client.post_request("transactions/#{id}/revise", body: params)
        Transaction.new(response.body["data"])
      end

      def invoice(id:, disposition: "attachment")
        response = Client.get_request("transactions/#{id}/invoice", params: { disposition: disposition })
        response.body["data"]["url"]
      end

      def preview(items:, **params)
        attrs = { items: items }
        response = Client.post_request("transactions/preview", body: attrs.merge(params))
        Transaction.new(response.body["data"])
      end
    end
  end
end
