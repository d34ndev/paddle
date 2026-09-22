module Paddle
  class Metric < Object
    class << self
      # from and to are dates, e.g. "2025-09-01" or a Date. Returns daily data with a timeseries
      def monthly_recurring_revenue(from:, to:)
        get("monthly-recurring-revenue", from: from, to: to)
      end

      def monthly_recurring_revenue_change(from:, to:)
        get("monthly-recurring-revenue-change", from: from, to: to)
      end

      def active_subscribers(from:, to:)
        get("active-subscribers", from: from, to: to)
      end

      def revenue(from:, to:)
        get("revenue", from: from, to: to)
      end

      def refunds(from:, to:)
        get("refunds", from: from, to: to)
      end

      def chargebacks(from:, to:)
        get("chargebacks", from: from, to: to)
      end

      def checkout_conversion(from:, to:)
        get("checkout-conversion", from: from, to: to)
      end

      # Lists the entities that can be queried with explore, with their dimensions and measures
      def explore_entities(**params)
        response = Client.get_request("metrics/explore/entities", params: params)
        Collection.from_response(response, type: ExploreEntity)
      end

      # Runs an Explore query. from is inclusive and to is exclusive.
      # measures is an array of hashes, e.g. [ { field: "gross_revenue", agg: "sum" } ]
      def explore(entity:, from:, to:, measures:, **params)
        query = { entity: entity, from: from, to: to, measures: measures }.merge(params)
        response = Client.post_request("metrics/explore", body: query)
        ExploreResult.from_response(response, query: query)
      end

      private

      def get(metric, from:, to:)
        response = Client.get_request("metrics/#{metric}", params: { from: from, to: to })
        Metric.new(response.body["data"])
      end
    end
  end
end
