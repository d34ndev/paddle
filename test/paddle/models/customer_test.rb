require "test_helper"

class CustomerTest < Minitest::Test
  def test_customer_list
    customers = Paddle::Customer.list

    assert_equal Paddle::Collection, customers.class
    assert_equal Paddle::Customer, customers.data.first.class
    assert_equal "ctm_01h7dtf1yg8jge7980baqdkjk8", customers.data.first.id
  end

  def test_customer_retrieve
    customer = Paddle::Customer.retrieve(id: "ctm_01h7dth5z8q7df4r73r4jek70g")

    assert_equal Paddle::Customer, customer.class
    assert_equal "ctm_01h7dth5z8q7df4r73r4jek70g", customer.id
    assert_equal "dean@mycompany.com", customer.email
  end

  def test_customer_create
    customer = Paddle::Customer.create(name: "Michael Bluth", email: "michael@mycompany.com")

    assert_equal Paddle::Customer, customer.class
    assert_equal "active", customer.status
    assert_equal "michael@mycompany.com", customer.email
  end

  def test_customer_create_with_spaces_in_email
    customer = Paddle::Customer.create(name: "Michael Bluth", email: " michael@mycompany.com ")

    assert_equal Paddle::Customer, customer.class
    assert_equal "active", customer.status
    assert_equal "michael@mycompany.com", customer.email
  end

  def test_customer_update
    customer = Paddle::Customer.update(id: "ctm_01h7dth5z8q7df4r73r4jek70g", email: "gob@bluthcompany.com")

    assert_equal Paddle::Customer, customer.class
    assert_equal "gob@bluthcompany.com", customer.email
  end

  def test_customer_credit
    credit = Paddle::Customer.credit(id: "ctm_01hd12bdgxkfjx1cj8ynmjyark")

    assert_equal Paddle::CreditBalance, credit.class
    assert_equal "USD", credit.currency_code
    assert_equal "0", credit.balance.available
  end

  def test_customer_credit_balances
    balances = Paddle::Customer.credit_balances(id: "ctm_01hd12bdgxkfjx1cj8ynmjyark")

    assert_equal Paddle::Collection, balances.class
    assert_equal 2, balances.total
    assert_equal Paddle::CreditBalance, balances.first.class
    assert_equal [ "USD", "GBP" ], balances.map(&:currency_code)
    assert_equal "1500", balances.last.balance.available
  end

  def test_customer_credit_balances_with_currency_code
    balances = Paddle::Customer.credit_balances(id: "ctm_01hd12bdgxkfjx1cj8ynmjyark", currency_code: "GBP")

    assert_equal 1, balances.total
    assert_equal "GBP", balances.first.currency_code
  end

  def test_object_update_without_ids
    VCR.use_cassette("test_customer_retrieve") do
      Paddle::Customer.retrieve(id: "ctm_01h7dth5z8q7df4r73r4jek70g").tap do |customer|
        VCR.use_cassette("test_customer_update") do
          customer.update(email: "gob@bluthcompany.com")
        end

        assert_equal Paddle::Customer, customer.class
        assert_equal "gob@bluthcompany.com", customer.email
      end
    end
  end

  def test_object_update_with_ids
    VCR.use_cassette("test_customer_retrieve") do
      Paddle::Customer.retrieve(id: "ctm_01h7dth5z8q7df4r73r4jek70g").tap do |customer|
        VCR.use_cassette("test_customer_update") do
          customer.update(email: "gob@bluthcompany.com", id: "lmao")
        end

        assert_equal Paddle::Customer, customer.class
        assert_equal "gob@bluthcompany.com", customer.email
        refute_equal "lmao", customer.id
      end
    end
  end
end
