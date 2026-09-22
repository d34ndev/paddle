require "test_helper"

class MetricTest < Minitest::Test
  METRICS = {
    monthly_recurring_revenue: "monthly-recurring-revenue",
    monthly_recurring_revenue_change: "monthly-recurring-revenue-change",
    active_subscribers: "active-subscribers",
    revenue: "revenue",
    refunds: "refunds",
    chargebacks: "chargebacks",
    checkout_conversion: "checkout-conversion"
  }

  def test_monthly_recurring_revenue
    metric = Paddle::Metric.monthly_recurring_revenue(from: "2025-09-01", to: "2025-09-05")

    assert_equal Paddle::Metric, metric.class
    assert_equal "day", metric.interval
    assert_equal "USD", metric.currency_code
    assert_equal "2025-09-01T00:00:00Z", metric.starts_at
    assert_equal "1286023068", metric.timeseries.first.amount
  end

  def test_checkout_conversion
    metric = Paddle::Metric.checkout_conversion(from: Date.new(2025, 9, 1), to: Date.new(2025, 9, 3))

    assert_equal 2, metric.timeseries.count
    assert_equal 151, metric.timeseries.first.count
    assert_equal 5, metric.timeseries.first.completed_count
    assert_equal "0.033113", metric.timeseries.first.rate
  end

  def test_each_metric_requests_its_endpoint
    VCR.use_cassette("test_metric_endpoints") do
      METRICS.each_key do |method|
        metric = Paddle::Metric.public_send(method, from: "2025-09-01", to: "2025-09-02")

        assert_equal Paddle::Metric, metric.class, method
        assert_equal method.to_s, metric.timeseries.first.metric, method
      end
    end
  end
end
