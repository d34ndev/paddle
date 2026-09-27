# Paddle Classic API

For accessing the Paddle Classic API. For the Billing API, see the [README](../README.md).

## Set Client Details

Firstly you'll need to set your Vendor ID, Vendor Auth Code and if you want
to use the Sandbox API or not.

You can find your vendor details [here for production](https://vendors.paddle.com/authentication),
or [here for sandbox](https://sandbox-vendors.paddle.com/authentication)

```ruby
@client = Paddle::Classic::Client.new(
  vendor_id: "",
  vendor_auth_code: "",
  # Use the sandbox version of the API
  sandbox: true
)
```

## Products

```ruby
# List all products
@client.products.list
```

## Plans

```ruby
# Retrieves a list of Plans
@client.plans.list

# Create a plan
# type can be "day", "week", "month" or "year"
# Returns the created Plan
@client.plans.create(
  name: "Pro",
  type: "month",
  plan_length: 1,
  plan_trial_days: 14,
  main_currency_code: "USD",
  recurring_price_usd: "10.00"
)
```

## Subscription Users

```ruby
# List all users subscribed to any plan
@client.users.list
@client.users.list(subscription_id: "abc123")
@client.users.list(plan_id: "abc123")
@client.users.list(state: "active")
@client.users.list(state: "deleted")

# Update a user's subscription
@client.users.update(subscription_id: "abc123")

# Pause a user's subscription
@client.users.pause(subscription_id: "abc123")

# Unpause a user's subscription
@client.users.unpause(subscription_id: "abc123")

# Update the Postcode/ZIP Code of a user's subscription
@client.users.update_postcode(subscription_id: "abc123", postcode: "123abc")

# Cancel a user's subscription
@client.users.cancel(subscription_id: "abc123")
```

## Payments

```ruby
# List all payments
@client.payments.list
@client.payments.list(subscription_id: "abc123")
@client.payments.list(plan: "abc123", is_paid: 1)
@client.payments.list(from: "2025-01-01", to: "2025-01-31")

# Reschedule an upcoming payment
# date should be in the format YYYY-MM-DD
# Returns true if successful
@client.payments.reschedule(payment_id: "abc123", date: "2025-02-01")

# Refund a payment
# Leave out amount to refund the full order
@client.payments.refund(order_id: "abc123")
@client.payments.refund(order_id: "abc123", amount: "5.00", reason: "Requested by customer")
```

## One-off Charges

```ruby
# Charge a subscription a one-off amount
@client.charges.create(subscription_id: "abc123", amount: "10.00", charge_name: "Extra seats")
```

## Modifiers

```ruby
# List all modifiers
@client.modifiers.list
@client.modifiers.list(subscription_id: "abc123")
@client.modifiers.list(plan_id: "abc123")

# Add a modifier to a subscription
# modifier_amount can be negative to give a discount
# Returns a Collection of the subscription's modifiers
@client.modifiers.create(
  subscription_id: "abc123",
  modifier_amount: "5.00",
  modifier_recurring: true,
  modifier_description: "Extra seat"
)

# Delete a modifier
# Returns true if successful
@client.modifiers.delete(modifier_id: "abc123")
```

## Coupons

```ruby
# List all coupons for a product
@client.coupons.list(product_id: "abc123")

# Create coupons
# coupon_type can be "product" or "checkout"
# discount_type can be "flat" or "percentage"
# Returns an array of Coupons with the generated codes
@client.coupons.create(
  coupon_type: "product",
  discount_type: "percentage",
  discount_amount: 10,
  product_ids: "abc123",
  num_coupons: 5,
  allowed_uses: 1
)

# Update a coupon, or a group of coupons
# Returns true if successful
@client.coupons.update(coupon_code: "ABC123", new_coupon_code: "XYZ123")
@client.coupons.update(group: "Black Friday", expires: "2025-12-01")

# Delete a coupon
# Returns true if successful
@client.coupons.delete(coupon_code: "ABC123", product_id: "abc123")
```

## Licenses

```ruby
# Generate a license for a product
@client.licenses.generate(product_id: "abc123", allowed_uses: 1)
@client.licenses.generate(product_id: "abc123", allowed_uses: 5, expires_at: "2025-12-31")
```

## Pay Links

```ruby
# Generate a pay link for a checkout
@client.pay_links.generate(
  product_id: "abc123",
  prices: ["USD:19.99"],
  customer_email: "customer@example.com",
  return_url: "https://example.com/thanks"
)
```

## Transactions

```ruby
# List transactions for a user, subscription, order, checkout or product
# entity can be "user", "subscription", "order", "checkout" or "product"
@client.transactions.list(entity: "subscription", id: "abc123")
```

## Webhooks

```ruby
# List past webhook alerts
@client.webhooks.list
@client.webhooks.list(page: 2, alerts_per_page: 50)
```
