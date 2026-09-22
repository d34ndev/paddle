require "test_helper"

class CollectionTest < Minitest::Test
  def test_pagination_attributes
    products = Paddle::Product.list(per_page: 2)

    assert_equal 2, products.per_page
    assert_equal 3, products.total
    assert products.has_more?
    assert_equal "https://sandbox-api.paddle.com/products?after=pro_02&per_page=2", products.next_url
  end

  def test_next_page
    products = Paddle::Product.list(per_page: 2)
    next_page = products.next_page

    assert_equal Paddle::Collection, next_page.class
    assert_equal Paddle::Product, next_page.first.class
    assert_equal [ "pro_03" ], next_page.map(&:id)
    refute next_page.has_more?
    assert_nil next_page.next_page
  end

  def test_auto_paging_each
    ids = []
    Paddle::Product.list(per_page: 2).auto_paging_each { |product| ids << product.id }

    assert_equal [ "pro_01", "pro_02", "pro_03" ], ids
  end

  def test_auto_paging_each_without_block
    products = Paddle::Product.list(per_page: 2).auto_paging_each

    assert_kind_of Enumerator, products
    assert_equal [ "pro_01", "pro_02" ], products.first(2).map(&:id)
  end

  def test_next_page_is_nil_when_has_more_is_false
    VCR.use_cassette("test_product_list") do
      products = Paddle::Product.list

      refute products.has_more?
      refute_nil products.next_url
      assert_nil products.next_page
    end
  end

  def test_unpaginated_response
    VCR.use_cassette("test_event_type_list") do
      event_types = Paddle::EventType.list

      refute event_types.has_more?
      assert_nil event_types.next_url
      assert_nil event_types.per_page
      assert_nil event_types.next_page
      assert_equal event_types.data.count, event_types.total
    end
  end

  def test_next_page_only_requests_the_configured_host
    collection = Paddle::Collection.new(
      data: [],
      total: 2,
      has_more: true,
      next_url: "https://evil.example.com/products?after=pro_01&per_page=1",
      type: Paddle::Product
    )

    next_page = collection.next_page

    assert_equal [ "pro_02" ], next_page.map(&:id)
  end
end
