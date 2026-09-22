require "test_helper"

class TransactionTest < Minitest::Test
  def test_transaction_list
    transactions = Paddle::Transaction.list

    assert_equal Paddle::Collection, transactions.class
    assert_equal Paddle::Transaction, transactions.data.first.class
    assert_equal "txn_01h7e2wz65er1fwbkqbzpng9th", transactions.data.first.id
    assert_equal "completed", transactions.data.first.status
  end

  def test_transaction_retrieve
    transaction = Paddle::Transaction.retrieve(id: "txn_01h7e2wz65er1fwbkqbzpng9th")

    assert_equal Paddle::Transaction, transaction.class
    assert_equal "txn_01h7e2wz65er1fwbkqbzpng9th", transaction.id
    assert_equal "subscription_update", transaction.origin
  end

  def test_transaction_retrieve_with_extra
    transaction = Paddle::Transaction.retrieve(id: "txn_01h7e2wz65er1fwbkqbzpng9th", extra: "customer")

    assert_equal Paddle::Transaction, transaction.class
    assert_equal "txn_01h7e2wz65er1fwbkqbzpng9th", transaction.id
    assert_equal "subscription_update", transaction.origin
    assert transaction.customer
  end

  def test_transaction_invoice
    invoice = Paddle::Transaction.invoice(id: "txn_01h7e2wz65er1fwbkqbzpng9th")

    assert_match (/paddle-sandbox-invoice-service-pdfs/), invoice
  end

  def test_transaction_invoice_inline
    invoice = Paddle::Transaction.invoice(id: "txn_01h7e2wz65er1fwbkqbzpng9th", disposition: "inline")

    assert_equal "https://paddle-sandbox-invoice-service-pdfs.s3.amazonaws.com/invoice.pdf", invoice
  end

  def test_transaction_create
    transaction = Paddle::Transaction.create(
      items: [
        {
          price_id: "pri_01h7dt1t5fhgpx7c4ze66vg3wt",
          quantity: 2
        }
      ]
    )

    assert_equal Paddle::Transaction, transaction.class
    assert_equal "txn_01h7e44011m1h8p70jgwcx23mg", transaction.id
    assert_equal "draft", transaction.status
  end

  def test_transaction_update
    transaction = Paddle::Transaction.update(id: "txn_01h7e44011m1h8p70jgwcx23mg",
      items: [
        {
          price_id: "pri_01h7dt1t5fhgpx7c4ze66vg3wt",
          quantity: 3
        }
      ]
    )

    assert_equal Paddle::Transaction, transaction.class
    assert_equal "draft", transaction.status
    assert_equal 3, transaction.items.last.quantity
  end

  def test_transaction_preview
    transaction = Paddle::Transaction.preview(
      items: [
        {
          price_id: "pri_01h7dt1t5fhgpx7c4ze66vg3wt",
          quantity: 2
        }
      ],
      currency_code: "GBP"
    )

    assert_equal Paddle::Transaction, transaction.class
    assert_equal 2, transaction.items.first.quantity
  end

  def test_transaction_revise
    VCR.use_cassette("test_transaction_revise_request", match_requests_on: [ :method, :uri, :body ]) do
      transaction = Paddle::Transaction.revise(
        id: "txn_01h7e0r43zjgzbcpqs093spymc",
        customer: { name: "Sam Miller" },
        business: { tax_identifier: "AB0123456789" },
        address: { first_line: "3811 Ditmars Blvd" }
      )

      assert_equal Paddle::Transaction, transaction.class
      assert_equal "txn_01h7e0r43zjgzbcpqs093spymc", transaction.id
      assert_equal "2026-09-22T10:00:00.000Z", transaction.revised_at
    end
  end
end
