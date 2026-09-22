require "test_helper"

class SubscriptionTest < Minitest::Test
  def test_subscription_list
    subscriptions = Paddle::Subscription.list

    assert_equal Paddle::Collection, subscriptions.class
    assert_equal Paddle::Subscription, subscriptions.data.first.class
    assert_equal "sub_01h7dvgvc6we84prca8gdhhr9c", subscriptions.data.first.id
  end

  def test_subscription_retrieve
    subscription = Paddle::Subscription.retrieve(id: "sub_01h7dvgvc6we84prca8gdhhr9c")

    assert_equal Paddle::Subscription, subscription.class
    assert_equal "sub_01h7dvgvc6we84prca8gdhhr9c", subscription.id
    assert_equal "active", subscription.status
  end

  def test_subscription_retrieve_with_extra
    subscription = Paddle::Subscription.retrieve(id: "sub_01h7dvgvc6we84prca8gdhhr9c", extra: "next_transaction")

    assert_equal Paddle::Subscription, subscription.class
    assert_equal "sub_01h7dvgvc6we84prca8gdhhr9c", subscription.id
    assert_equal "active", subscription.status
    assert subscription.next_transaction
  end

  def test_subscription_get_transaction
    transaction = Paddle::Subscription.get_transaction(id: "sub_01h7dvgvc6we84prca8gdhhr9c")

    assert_equal Paddle::Transaction, transaction.class
    assert_equal "txn_01h7dxza6whtgdcnb9f1h377j9", transaction.id
    assert_equal "sub_01h7dvgvc6we84prca8gdhhr9c", transaction.subscription_id
  end

  def test_subscription_preview
    subscription = Paddle::Subscription.preview(id: "sub_01h7dvgvc6we84prca8gdhhr9c",
      items: [
        {
          price_id: "pri_01h7dt1t5fhgpx7c4ze66vg3wt",
          quantity: 2
        }
      ],
      proration_billing_mode: "full_next_billing_period"
    )

    assert_equal Paddle::Subscription, subscription.class
    assert_equal "active", subscription.status
    assert_equal 2, subscription.recurring_transaction_details.line_items.first.quantity
  end

  def test_subscription_update
    subscription = Paddle::Subscription.update(id: "sub_01h7dvgvc6we84prca8gdhhr9c", billing_details: { purchase_order_number: "PO-1234" })

    assert_equal Paddle::Subscription, subscription.class
    assert_equal "active", subscription.status
    assert_equal "sub_01h7dvgvc6we84prca8gdhhr9c", subscription.id
    assert_equal "PO-1234", subscription.billing_details.purchase_order_number
  end

  def test_subscription_charge_preview
    VCR.use_cassette("test_subscription_charge_preview_request", match_requests_on: [ :method, :uri, :body ]) do
      subscription = Paddle::Subscription.charge_preview(id: "sub_01h7dvgvc6we84prca8gdhhr9c",
        effective_from: "immediately",
        items: [
          {
            price_id: "pri_01h7dy3z54j3q6ehcd0gvk35mb",
            quantity: 1
          }
        ]
      )

      assert_equal Paddle::Subscription, subscription.class
      assert_equal "sub_01h7dvgvc6we84prca8gdhhr9c", subscription.id
      assert_equal "1000", subscription.immediate_transaction.details.totals.grand_total
      assert_equal "pri_01h7dy3z54j3q6ehcd0gvk35mb", subscription.immediate_transaction.details.line_items.first.price_id
    end
  end

  def test_subscription_pause
    subscription = Paddle::Subscription.pause(id: "sub_01h7dvgvc6we84prca8gdhhr9c", effective_from: "immediately")

    assert_equal Paddle::Subscription, subscription.class
    assert_equal "active", subscription.status
    assert_equal "sub_01h7dvgvc6we84prca8gdhhr9c", subscription.id
    assert_equal "pause", subscription.scheduled_change.action
  end

  def test_subscription_resume
    subscription = Paddle::Subscription.resume(id: "sub_01hd14fsxw4tp9tt7ajsk57qsv", effective_from: "immediately")

    assert_equal Paddle::Subscription, subscription.class
    assert_equal "active", subscription.status
    assert_equal "sub_01hd14fsxw4tp9tt7ajsk57qsv", subscription.id
  end

  def test_subscription_charge
    subscription = Paddle::Subscription.charge(id: "sub_01h7dvgvc6we84prca8gdhhr9c",
      effective_from: "immediately",
      items: [
        {
          price_id: "pri_01h7dy3z54j3q6ehcd0gvk35mb",
          quantity: 1
        }
      ]
    )

    assert_equal Paddle::Subscription, subscription.class
    assert_equal "active", subscription.status
  end

  def test_subscription_cancel
    subscription = Paddle::Subscription.cancel(id: "sub_01h7dvgvc6we84prca8gdhhr9c", effective_from: "next_billing_period")

    assert_equal Paddle::Subscription, subscription.class
    assert_equal "active", subscription.status
    assert_equal "sub_01h7dvgvc6we84prca8gdhhr9c", subscription.id
    assert_equal "cancel", subscription.scheduled_change.action
  end

  def test_subscription_activate
    subscription = Paddle::Subscription.activate(id: "sub_01hd1drf5htjz45yt2346anmqt")

    assert_equal Paddle::Subscription, subscription.class
    assert_equal "active", subscription.status
    assert_equal "sub_01hd1drf5htjz45yt2346anmqt", subscription.id
  end

  def test_subscription_history
    history = Paddle::Subscription.history(id: "sub_01h04vsc0qhwtsbsxh3422wjs4", action: "subscription_canceled", per_page: 1)

    assert_equal Paddle::Collection, history.class
    assert_equal Paddle::SubscriptionHistory, history.first.class
    assert_equal "subhis_01kagxfkdpvsdvnm7xw4avwvsp", history.first.id
    assert_equal "api", history.first.source
    assert_equal "api_key", history.first.actor.type
    assert_equal "subscription_canceled", history.first.detail.action
    assert history.has_more?
  end
end
