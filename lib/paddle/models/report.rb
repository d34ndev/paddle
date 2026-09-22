module Paddle
  class Report < Object
    class << self
      def list(**params)
        response = Client.get_request("reports", params: params)
        Collection.from_response(response, type: Report)
      end

      def create(type:, filters:, **params)
        attrs = { type: type, filters: filters }
        response = Client.post_request("reports", body: attrs.merge(params))
        Report.new(response.body["data"])
      end

      def retrieve(id:)
        response = Client.get_request("reports/#{id}")
        Report.new(response.body["data"])
      end

      def csv(id:)
        response = Client.get_request("reports/#{id}/download-url")
        response.body["data"]["url"]
      end
    end
  end
end
