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

  EXPLORE_QUERY = {
    entity: "transactions.completed",
    from: "2026-05-01",
    to: "2026-08-01",
    interval: "month",
    dimensions: [ "product" ],
    measures: [ { field: "gross_revenue", agg: "sum" } ],
    order_by: [ { field: "gross_revenue", dir: "desc" } ],
    per_page: 1
  }

  def test_explore_entities
    entities = Paddle::Metric.explore_entities(entity: "adjustments.chargebacks")

    assert_equal Paddle::Collection, entities.class
    assert_equal Paddle::ExploreEntity, entities.first.class
    assert_equal "adjustments.chargebacks", entities.first.entity
    assert_equal [ "day", "week", "month" ], entities.first.time_dimension.intervals
    assert_equal "product", entities.first.dimensions.first.name
  end

  def test_explore
    VCR.use_cassette("test_explore_pages", match_requests_on: [ :method, :uri, :body_as_json ]) do
      result = Paddle::Metric.explore(**EXPLORE_QUERY)

      assert_equal Paddle::ExploreResult, result.class
      assert_equal "transactions.completed", result.entity
      assert_equal "sum_gross_revenue", result.fields.measures.first.name
      assert_equal "pro_01h1vjfevh5etwq3rb416a23h2", result.series.first.dimensions.product
      assert_equal "410500", result.series.first.timeseries.first.measures.sum_gross_revenue
      assert_equal 1, result.per_page
      assert_equal 2, result.total
      assert result.has_more?
    end
  end

  def test_explore_next_page
    VCR.use_cassette("test_explore_pages", match_requests_on: [ :method, :uri, :body_as_json ]) do
      next_page = Paddle::Metric.explore(**EXPLORE_QUERY).next_page

      assert_equal Paddle::ExploreResult, next_page.class
      assert_equal "pro_01gsz4t5hdjse780zja8vvr7jg", next_page.series.first.dimensions.product
      refute next_page.has_more?
      assert_nil next_page.next_page
    end
  end

  def test_explore_auto_paging_each
    VCR.use_cassette("test_explore_pages", match_requests_on: [ :method, :uri, :body_as_json ]) do
      products = Paddle::Metric.explore(**EXPLORE_QUERY).auto_paging_each.map { |series| series.dimensions.product }

      assert_equal [ "pro_01h1vjfevh5etwq3rb416a23h2", "pro_01gsz4t5hdjse780zja8vvr7jg" ], products
    end
  end

  def test_explore_next_page_only_requests_the_configured_host
    VCR.use_cassette("test_explore_pages", match_requests_on: [ :method, :uri, :body_as_json ]) do
      result = Paddle::ExploreResult.new(
        { "series" => [] },
        query: EXPLORE_QUERY,
        pagination: { "has_more" => true, "next" => "https://evil.example.com/metrics/explore?after=eyJvZmYiOjF9" }
      )

      assert_equal "pro_01gsz4t5hdjse780zja8vvr7jg", result.next_page.series.first.dimensions.product
    end
  end
end
