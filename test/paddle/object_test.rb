require "test_helper"

class ObjectTest < Minitest::Test
  def test_creating_object_from_hash
    assert_equal "bar", Paddle::Object.new(foo: "bar").foo
  end

  def test_nested_hash
    assert_equal "foobar", Paddle::Object.new(foo: { bar: { baz: "foobar" } }).foo.bar.baz
  end

  def test_nested_number
    assert_equal 1, Paddle::Object.new(foo: { bar: 1 }).foo.bar
  end

  def test_array
    object = Paddle::Object.new(foo: [ { bar: :baz } ])
    assert_equal Paddle::Object, object.foo.first.class
    assert_equal :baz, object.foo.first.bar
  end

  def test_hash_access
    object = Paddle::Object.new("id" => "txn_abc123")
    assert_equal "txn_abc123", object[:id]
    assert_equal "txn_abc123", object["id"]
  end

  def test_missing_attribute_returns_nil
    object = Paddle::Object.new(foo: "bar")
    assert_nil object.baz
    refute object.respond_to?(:baz)
    assert object.respond_to?(:foo)
  end

  def test_setting_attributes
    object = Paddle::Object.new(foo: "bar")
    object.foo = "baz"
    object[:qux] = { quux: 1 }
    assert_equal "baz", object.foo
    assert_equal 1, object.qux.quux
  end

  def test_attributes_named_after_private_methods
    object = Paddle::Object.new(format: "pdf", test: true)
    assert_equal "pdf", object.format
    assert_equal true, object.test
  end

  def test_unknown_method_with_arguments_raises
    assert_raises(NoMethodError) { Paddle::Object.new(foo: "bar").foo(1) }
  end

  def test_dig
    object = Paddle::Object.new(items: [ { price: { id: "pri_abc123" } } ])
    assert_equal "pri_abc123", object.dig(:items, 0, :price, :id)
    assert_nil object.dig(:missing, :id)
  end

  def test_to_h_converts_nested_objects
    object = Paddle::Object.new(foo: { bar: [ { baz: 1 } ] })
    assert_equal({ foo: { bar: [ { baz: 1 } ] } }, object.to_h)
  end

  def test_to_json
    object = Paddle::Object.new(foo: { bar: "baz" })
    assert_equal '{"foo":{"bar":"baz"}}', object.to_json
  end

  def test_equality
    assert_equal Paddle::Object.new(foo: { bar: 1 }), Paddle::Object.new("foo" => { "bar" => 1 })
    refute_equal Paddle::Object.new(foo: 1), Paddle::Object.new(foo: 2)
  end

  def test_nil_attributes
    assert_equal({}, Paddle::Object.new(nil).to_h)
  end
end
