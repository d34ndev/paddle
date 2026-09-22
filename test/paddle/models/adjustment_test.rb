require "test_helper"

class AdjustmentTest < Minitest::Test
  def test_adjustment_list
    adjustments = Paddle::Adjustment.list

    assert_equal Paddle::Collection, adjustments.class
    assert_equal Paddle::Adjustment, adjustments.data.first.class
    assert_equal "credit", adjustments.data.first.action
  end

  def test_adjustment_create
    adjustment = Paddle::Adjustment.create(
      action: "credit",
      transaction_id: "txn_01h7e0r43zjgzbcpqs093spymc",
      reason: "error",
      items: [
        {
          type: "full",
          item_id: "txnitm_01h7e0rc8we655bjx8km2kpyg0"
        }
      ]
    )

    assert_equal Paddle::Adjustment, adjustment.class
    assert_equal "credit", adjustment.action
  end

  def test_adjustment_create_full
    VCR.use_cassette("test_adjustment_create_full_without_items", match_requests_on: [ :method, :uri, :body ]) do
      adjustment = Paddle::Adjustment.create(
        action: "refund",
        transaction_id: "txn_01h7e0r43zjgzbcpqs093spymc",
        reason: "error",
        type: "full"
      )

      assert_equal Paddle::Adjustment, adjustment.class
      assert_equal "full", adjustment.type
      assert_equal "2499", adjustment.totals.total
    end
  end

  def test_adjustment_credit_note
    credit_note = Paddle::Adjustment.credit_note(id: "adj_01h7e2wz3srndp9f5ttbgn6dhp")

    assert_equal "https://paddle-sandbox-invoice-service-pdfs.s3.amazonaws.com/credit-note.pdf", credit_note
  end

  def test_adjustment_credit_note_inline
    credit_note = Paddle::Adjustment.credit_note(id: "adj_01h7e2wz3srndp9f5ttbgn6dhp", disposition: "inline")

    assert_equal "https://paddle-sandbox-invoice-service-pdfs.s3.amazonaws.com/credit-note.pdf", credit_note
  end
end
