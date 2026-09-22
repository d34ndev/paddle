module Paddle
  class Adjustment < Object
    class << self
      def list(**params)
        response = Client.get_request("adjustments", params: params)
        Collection.from_response(response, type: Adjustment)
      end

      # items can be omitted when type is "full"
      def create(transaction_id:, action:, reason:, items: nil, **params)
        attrs = { transaction_id: transaction_id, action: action, reason: reason }
        attrs[:items] = items if items
        response = Client.post_request("adjustments", body: attrs.merge(params))
        Adjustment.new(response.body["data"])
      end

      def credit_note(id:, disposition: "attachment")
        response = Client.get_request("adjustments/#{id}/credit-note", params: { disposition: disposition })
        response.body["data"]["url"]
      end
    end
  end
end
