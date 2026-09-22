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

      private

      def get(metric, from:, to:)
        response = Client.get_request("metrics/#{metric}", params: { from: from, to: to })
        Metric.new(response.body["data"])
      end
    end
  end
end
