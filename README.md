# Paddle Ruby Library

The easiest and most complete Ruby library for the Paddle APIs, both Classic and Billing.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "paddle", "~> 2.10"
```

## Billing API

For accessing the new Billing API from Paddle. For more info, view the [Paddle Billing](https://www.paddle.com/billing) page.

### Configuration

Firstly you'll need to generate and set your API Key and the environment.

You can find and generate an API key [here for production](https://vendors.paddle.com/authentication),
or [here for sandbox](https://sandbox-vendors.paddle.com/authentication)

```ruby
Paddle.configure do |config|
  # Use :development or :sandbox for the Sandbox API
  # Or use :production for the Production API
  config.environment = :sandbox
  config.api_key = ENV["PADDLE_API_KEY"]

  # Set the API version. Defaults to 1
  config.version = 1
end
```

### Connection Options

You can pass [options](https://lostisland.github.io/faraday/#/customization/connection-options) to the underlying [Faraday](https://lostisland.github.io/faraday/) connection using `connection_options`. This is useful for setting timeouts, proxies, or SSL configuration:

```ruby
Paddle.configure do |config|
  config.environment = :sandbox
  config.api_key = ENV["PADDLE_API_KEY"]

  config.connection_options = {
    request: { timeout: 10, open_timeout: 5 }
  }
end
```

### Resources

The gem maps as closely as we can to the Paddle API so you can easily convert API examples to gem code.

Responses are created as objects like `Paddle::Product`. Having types like `Paddle::Product` is handy for understanding what
type of object you're working with. They're built using OpenStruct so you can easily access data in a Ruby-ish way.

### Pagination

Some of the endpoints return pages of results. The result object will have a `data` key to access the results.

An example of using collections, including pagination:

```ruby
results = Paddle::Product.list(per_page: 10)
#=> Paddle::Collection

results.total
#=> 10

results.per_page
#=> 10

results.has_more?
#=> true

results.data
#=> [#<Paddle::Product>, #<Paddle::Product>]

results.each do |result|
  puts result.id
end

results.first
#=> #<Paddle::Product>

results.last
#=> #<Paddle::Product>

# Retrieve the next page. Returns nil when there are no more pages
results.next_page
#=> Paddle::Collection

# Or use the after cursor directly
Paddle::Product.list(per_page: 10, after: "abc123")
#=> Paddle::Collection

# Iterate over every result across all pages, fetching each page as it's needed
Paddle::Product.list(per_page: 50).auto_paging_each do |product|
  puts product.id
end

# Without a block, auto_paging_each returns an Enumerator. Pages are only fetched until a match is found
Paddle::Customer.list.auto_paging_each.find { |customer| customer.email == "michael@mycompany.com" }
```

>[!NOTE]
>
> `total` is Paddle's `estimated_total`. For lists of more than 100,000 results it's capped at `100001`,
> and it's `-1` when Paddle can't count the results. Use `has_more?`, `next_page` or `auto_paging_each`
> to page through results rather than relying on `total`.

If you don't need `total`, pass `skip_count: true` to any list method. This sends the `Skip-Count` header,
so Paddle skips counting the results and responds faster. `total` will be `-1`, and `next_page` and
`auto_paging_each` keep sending the header for later pages.

```ruby
Paddle::Transaction.list(skip_count: true).auto_paging_each do |transaction|
  puts transaction.id
end
```

### Caveats

>[!NOTE]
>
> The Paddle API doesn't take `nil` values for optional parameters. If you want to remove a value, you'll need to pass `"null"` instead.

When filtering a list, you can pass an array or a comma-separated string to filter by more than one value. Arrays are sent as comma-separated lists, as Paddle expects:

```ruby
Paddle::Subscription.list(status: [ "active", "past_due" ])
# is the same as
Paddle::Subscription.list(status: "active,past_due")
```

### Error Handling

When API requests fail, the gem provides detailed error information to help you debug issues. Errors are raised as exceptions with comprehensive details including field-level validation errors.

#### Error Structure

All errors inherit from `Paddle::ErrorGenerator` and include:

- HTTP status code
- Error code from Paddle
- Detailed error message
- Field-specific validation errors (when applicable)
- Documentation URL for more information
- Request ID for support

#### Available Error Classes

- `Paddle::Errors::BadRequestError` (400) - Invalid request parameters
- `Paddle::Errors::AuthenticationMissingError` (401) - Missing or invalid API credentials
- `Paddle::Errors::ForbiddenError` (403) - Insufficient permissions
- `Paddle::Errors::EntityNotFoundError` (404) - Resource not found
- `Paddle::Errors::ConflictError` (409) - Request conflicts with existing data
- `Paddle::Errors::TooManyRequestsError` (429) - Rate limit exceeded
- `Paddle::Errors::InternalError` (500) - Server error
- `Paddle::Errors::ServiceUnavailableError` (503) - Service unavailable

#### Error Example

When creating a Price with invalid parameters, you'll receive a detailed error:

```ruby
begin
  Paddle::Price.create(product_id: "pro_123", trial_period: { frequency: "monthly" })
rescue Paddle::Errors::BadRequestError => e
  puts e.message
  # => Error 400: Invalid request. 'bad_request'
  #    Field errors:
  #      - trial_period.frequency: Invalid type. Expected: integer, given: string
  #      - trial_period: Must validate one and only one schema (oneOf)
  #    Documentation: https://developer.paddle.com/v1/errors/shared/bad_request
  #    Request ID: e385967f-4298-4240-a971-f988209b32ca

  # Access error details programmatically
  e.http_status_code      #=> 400
  e.paddle_error_code     #=> "bad_request"
  e.paddle_error_message  #=> "Invalid request."
  e.paddle_errors         #=> [{"field"=>"trial_period.frequency", "message"=>"Invalid type. Expected: integer, given: string"}, ...]
  e.documentation_url     #=> "https://developer.paddle.com/v1/errors/shared/bad_request"
  e.request_id            #=> "e385967f-4298-4240-a971-f988209b32ca"
end
```

### Updating records

For API endpoints that support it, you can use the `update` method to update a record, like so:

```ruby
Paddle::Product.retrieve(id: "pro_abc123").update(name: "My New Name")
```

### Products

```ruby
# List all products
# https://developer.paddle.com/api-reference/products/list-products
Paddle::Product.list
Paddle::Product.list(status: "active")
Paddle::Product.list(status: "archived")
Paddle::Product.list(tax_category: "saas")

# Create a product
# https://developer.paddle.com/api-reference/products/create-product
Paddle::Product.create(name: "My SAAS Plan", tax_category: "saas")
Paddle::Product.create(name: "My Standard Product", tax_category: "standard")

# Retrieve a product
product = Paddle::Product.retrieve(id: "pro_abc123")

# Update a product
# https://developer.paddle.com/api-reference/products/update-product
product.update(description: "This is a plan")
# or
Paddle::Product.update(id: "pro_abc123", description: "This is a plan")
```

### Prices

```ruby
# List all prices
# https://developer.paddle.com/api-reference/prices/list-prices
Paddle::Price.list
Paddle::Price.list(status: "active")
Paddle::Price.list(status: "archived")
Paddle::Price.list(product_id: "pro_abc123")

# Create a price
# Note that unit_price amount should be a string
# https://developer.paddle.com/api-reference/prices/create-price
Paddle::Price.create(product_id: "pro_abc123", description: "A one off price", amount: "1000", currency: "GBP")

# Retrieve a price
price = Paddle::Price.retrieve(id: "pri_123abc")

# Update a price
# https://developer.paddle.com/api-reference/prices/update-price
price.update(description: "An updated description")
# or
Paddle::Price.update(id: "pri_123abc", description: "An updated description")
```

### Pricing Preview

```ruby
# Preview calculations for one or more prices
# This is normally used when building pricing pages
# https://developer.paddle.com/api-reference/pricing-preview/preview-prices
Paddle::PricingPreview.generate(items: [ { price_id: "pri_123abc", quantity: 5 } ])
Paddle::PricingPreview.generate(items: [ { price_id: "pri_123abc", quantity: 5 } ], currency_code: "GBP")
Paddle::PricingPreview.generate(items: [ { price_id: "pri_123abc", quantity: 5 } ], customer_ip_address: "1.1.1.1")
```

### Discounts

```ruby
# List all discounts
# https://developer.paddle.com/api-reference/discounts/list-discounts
Paddle::Discount.list
Paddle::Discount.list(status: "active")

# Create a discount
# Note that amount should be a string
# https://developer.paddle.com/api-reference/discounts/create-discount
Paddle::Discount.create(description: "$5 off", type: "flat", amount: "500", currency_code: "USD")
Paddle::Discount.create(description: "10% Off", type: "percentage", amount: "10", code: "10OFF")

# Retrieve a discount
discount = Paddle::Discount.retrieve(id: "dsc_abc123")

# Update a discount
# https://developer.paddle.com/api-reference/discounts/update-discount
discount.update(description: "An updated description")
# or
Paddle::Discount.update(id: "dsc_abc123", description: "An updated description")
```

### Discount Groups

```ruby
# List all discount groups
# https://developer.paddle.com/api-reference/discount-groups/list-discount-groups
Paddle::DiscountGroup.list
Paddle::DiscountGroup.list(status: "active")

# Create a discount group
# https://developer.paddle.com/api-reference/discount-groups/create-discount-group
Paddle::DiscountGroup.create(name: "Black Friday Promotion")

# Retrieve a discount group
# https://developer.paddle.com/api-reference/discount-groups/get-discount-group
discount_group = Paddle::DiscountGroup.retrieve(id: "dsg_abc123")

# Update a discount group
# https://developer.paddle.com/api-reference/discount-groups/update-discount-group
discount_group.update(name: "Updated name")
# or
Paddle::DiscountGroup.update(id: "dsg_abc123", name: "Updated name")

# Create a discount in a discount group
discount_group.create_discount(description: "$10 off", type: "flat", amount: "1000", currency_code: "USD")
# or
Paddle::Discount.create(discount_group_id: discount_group.id, description: "$10 off", type: "flat", amount: "1000", currency_code: "USD")

# List discounts in a discount group
discounts = discount_group.discounts
```

### Customers

```ruby
# List all customers
# https://developer.paddle.com/api-reference/customers/list-customers
Paddle::Customer.list
Paddle::Customer.list(status: "active")
Paddle::Customer.list(email: "me@mydomain.com")

# Create a customer
# https://developer.paddle.com/api-reference/customers/create-customer
# Returns a Paddle::Errors::ConflictError if the email is already used on Paddle
Paddle::Customer.create(email: "myemail@mydomain.com", name: "Customer Name")

# Retrieve a customer
customer = Paddle::Customer.retrieve(id: "ctm_abc123")

# Update a customer
# https://developer.paddle.com/api-reference/customers/update-customer
customer.update(status: "archived")
# or
Paddle::Customer.update(id: "ctm_abc123", status: "archived")

# List credit balances for a customer. Customers have a balance for each currency
# https://developer.paddle.com/api-reference/customers/list-credit-balances
Paddle::Customer.credit_balances(id: "ctm_abc123")
Paddle::Customer.credit_balances(id: "ctm_abc123", currency_code: "USD")

# Retrieve the first credit balance for a customer
Paddle::Customer.credit(id: "ctm_abc123")

# Generate an authentication token for a customer
# https://developer.paddle.com/api-reference/customers/generate-customer-authentication-token
Paddle::Customer.auth_token id: "ctm_abc123"
#=> #<Paddle::CustomerAuthToken customer_auth_token="pca_abc123", expires_at="2025-12-10T16:21:21.554Z">
```

### Addresses

```ruby
# List all addresses for a customer
# https://developer.paddle.com/api-reference/addresses/list-addresses
Paddle::Address.list(customer: "ctm_abc123")

# Create an address
# https://developer.paddle.com/api-reference/addresses/create-address
Paddle::Address.create(customer: "ctm_abc123", country_code: "GB", postal_code: "SW1A 2AA")

# Retrieve an address
address = Paddle::Address.retrieve(customer: "ctm_abc123", id: "add_abc123")

# Update an address
# https://developer.paddle.com/api-reference/addresses/update-address
address.update(status: "archived")
# or
Paddle::Address.update(customer: "ctm_abc123", id: "add_abc123", status: "archived")
```

### Businesses

```ruby
# List all businesses for a customer
# https://developer.paddle.com/api-reference/businesses/list-businesses
Paddle::Business.list(customer: "ctm_abc123")

# Create a business
# https://developer.paddle.com/api-reference/businesses/create-business
Paddle::Business.create(customer: "ctm_abc123", name: "My Ltd Company")

# Retrieve a business
business = Paddle::Business.retrieve(customer: "ctm_abc123", id: "biz_abc123")

# Update a business
# https://developer.paddle.com/api-reference/businesses/update-business
business.update(status: "archived")
# or
Paddle::Business.update(customer: "ctm_abc123", id: "biz_abc123", status: "archived")
```

### Transactions

```ruby
# List all transactions
# https://developer.paddle.com/api-reference/transactions/list-transactions
Paddle::Transaction.list(customer_id: "ctm_abc123")
Paddle::Transaction.list(subscription_id: "sub_abc123")
Paddle::Transaction.list(status: "completed")

# Create a transaction
# https://developer.paddle.com/api-reference/transactions/create-transaction
Paddle::Transaction.create(items: [ { price_id: "pri_abc123", quantity: 1 } ])

# Retrieve a transaction
Paddle::Transaction.retrieve(id: "txn_abc123")

# Retrieve a transaction with extra information
# extra can be either "address", "adjustment", "adjustments_totals", "business", "customer", "discount"
transaction = Paddle::Transaction.retrieve(id: "txn_abc123", extra: "customer")

# Update a transaction
# https://developer.paddle.com/api-reference/transaction/update-transaction
transaction.update(items: [ { price_id: "pri_abc123", quantity: 2 } ])
# or
Paddle::Transaction.update(id: "txn_abc123", items: [ { price_id: "pri_abc123", quantity: 2 } ])

# Preview a transaction
# https://developer.paddle.com/api-reference/transaction/preview-transaction
Paddle::Transaction.preview(items: [ { price_id: "pri_123abc", quantity: 5 } ])

# Get a PDF invoice for a transaction
# disposition defaults to "attachment"
# Returns a raw URL. This URL is not permanent and will expire.
# https://developer.paddle.com/api-reference/transaction/get-invoice-pdf
Paddle::Transaction.invoice(id: "txn_abc123", disposition: "inline")
#=> https://paddle-sandbox-invoice...

# Revise customer, business and address details on a billed or completed transaction
# Only address lines, city and region can be changed, and a transaction can only be revised once.
# The related customer, business and address records aren't updated
# https://developer.paddle.com/api-reference/transactions/revise-transaction
Paddle::Transaction.revise(
  id: "txn_abc123",
  customer: { name: "Sam Miller" },
  business: { tax_identifier: "AB0123456789" },
  address: { first_line: "3811 Ditmars Blvd" }
)
```

### Subscriptions

```ruby
# List all subscriptions
# https://developer.paddle.com/api-reference/subscriptions/list-subscriptions
Paddle::Subscription.list(customer_id: "ctm_abc123")
Paddle::Subscription.list(price_id: "pri_abc123")
Paddle::Subscription.list(status: "active")
Paddle::Subscription.list(status: "canceled")
Paddle::Subscription.list(collection_mode: "automatic")
Paddle::Subscription.list(scheduled_change_action: "cancel")

# Retrieve a subscription
Paddle::Subscription.retrieve(id: "sub_abc123")

# Retrieve a subscription with extra information
# extra can be either "next_transaction" or "recurring_transaction_details"
subscription = Paddle::Subscription.retrieve(id: "sub_abc123", extra: "next_transaction")

# Preview an update to a subscription
# https://developer.paddle.com/api-reference/subscriptions/preview-subscription
Paddle::Subscription.preview(id: "sub_abc123", items: [ { price_id: "pri_123abc", quantity: 2 } ])

# Update a subscription
# https://developer.paddle.com/api-reference/subscriptions/update-subscription
subscription.update(billing_details: {purchase_order_number: "PO-1234"})
# or
Paddle::Subscription.update(id: "sub_abc123", billing_details: {purchase_order_number: "PO-1234"})

# Get a transaction to update payment method
# https://developer.paddle.com/api-reference/subscriptions/update-payment-method
Paddle::Subscription.get_transaction(id: "sub_abc123")

# Create a one-time charge for a subscription
# https://developer.paddle.com/api-reference/subscriptions/create-one-time-charge
Paddle::Subscription.charge(id: "sub_abc123", items: [ { price_id: "pri_123abc", quantity: 2 } ], effective_from: "immediately")

# Preview a one-time charge for a subscription without billing it
# Returns a Subscription with immediate_transaction and next_transaction previews
# https://developer.paddle.com/api-reference/subscriptions/preview-subscription-charge
Paddle::Subscription.charge_preview(id: "sub_abc123", items: [ { price_id: "pri_123abc", quantity: 2 } ], effective_from: "immediately")

# Pause a subscription
# https://developer.paddle.com/api-reference/subscriptions/pause-subscription
Paddle::Subscription.pause(id: "sub_abc123")
Paddle::Subscription.pause(id: "sub_abc123", effective_from: "next_billing_period")
Paddle::Subscription.pause(id: "sub_abc123", effective_from: "immediately")

# Resume a paused subscription
# https://developer.paddle.com/api-reference/subscriptions/resume-subscription
Paddle::Subscription.resume(id: "sub_abc123", effective_from: "next_billing_period")
Paddle::Subscription.resume(id: "sub_abc123", effective_from: "immediately")

# Cancel a subscription
# https://developer.paddle.com/api-reference/subscriptions/cancel-subscription
Paddle::Subscription.cancel(id: "sub_abc123", effective_from: "next_billing_period")
Paddle::Subscription.cancel(id: "sub_abc123", effective_from: "immediately")

# Activate a trialing subscription
# https://developer.paddle.com/api-reference/subscriptions/activate-subscription
Paddle::Subscription.activate(id: "sub_abc123")

# List the history of a subscription, newest first
# Returns a Paddle::Collection of Paddle::SubscriptionHistory
# https://developer.paddle.com/api-reference/subscription-history/list-subscription-history
Paddle::Subscription.history(id: "sub_abc123")
Paddle::Subscription.history(id: "sub_abc123", action: [ "subscription_created", "subscription_canceled" ])
Paddle::Subscription.history(id: "sub_abc123", source: "customer_portal", actor_type: "customer")
Paddle::Subscription.history(id: "sub_abc123", "occurred_at[GTE]": "2026-01-01T00:00:00Z")

Paddle::Subscription.history(id: "sub_abc123").auto_paging_each do |entry|
  puts "#{entry.occurred_at} #{entry.detail.action} by #{entry.actor.type} via #{entry.source}"
end
```

### Customer Portal Sessions

```ruby
# Create a Customer Portal Session
# https://developer.paddle.com/api-reference/customer-portals/create-customer-portal-session
Paddle::PortalSession.create customer: "ctm_abc123"
Paddle::PortalSession.create customer: "ctm_abc123", subscription_ids: ["sub_abc123"]
```

### Adjustments

```ruby
# List all adjustments
# https://developer.paddle.com/api-reference/adjustments/list-adjustments
Paddle::Adjustment.list(subscription_id: "sub_abc123")
Paddle::Adjustment.list(transaction_id: "txn_abc123")
Paddle::Adjustment.list(action: "refund")

# Create an adjustment
# https://developer.paddle.com/api-reference/adjustments/create-adjustment
Paddle::Adjustment.create(
  action: "refund",
  transaction_id: "txn_abc123",
  reason: "Requested by customer",
  items: [
    {
      type: "full",
      item_id: "txnitm_anc123"
    }
  ]
)

# Refund or credit the grand total of a transaction without specifying items
Paddle::Adjustment.create(
  action: "refund",
  transaction_id: "txn_abc123",
  reason: "Requested by customer",
  type: "full"
)

# Get a credit note for an adjustment
# disposition defaults to "attachment"
# Returns a raw URL. This URL is not permanent and will expire.
# https://developer.paddle.com/api-reference/adjustments/get-credit-note-pdf
Paddle::Adjustment.credit_note(id: "adj_abc123", disposition: "inline")
```

### Payment Methods

```ruby
# List all payment methods for a customer
# https://developer.paddle.com/api-reference/payment-methods/list-payment-methods
Paddle::PaymentMethod.list customer: "ctm_abc123"

# Retrieve a single payment method for a customer
# https://developer.paddle.com/api-reference/payment-methods/get-payment-method
Paddle::PaymentMethod.retrieve customer: "ctm_abc123", id: "paymtd_abc123"

# Delete a payment method for a customer
# https://developer.paddle.com/api-reference/payment-methods/delete-payment-method
Paddle::PaymentMethod.delete customer: "ctm_abc123", id: "paymtd_abc123"
```

### Event Types

```ruby
# List all event types
Paddle::EventType.list
```

### Events

```ruby
# List all events
# https://developer.paddle.com/api-reference/events/list-events
Paddle::Event.list
```

### Notification Settings

Used for creating webhook and email notifications

```ruby
# List all notification settings
Paddle::NotificationSetting.list

# Retrieve a notification setting
setting = Paddle::NotificationSetting.retrieve(id: "ntfset_abc123")

# Create a notification setting
# https://developer.paddle.com/api-reference/notification-settings/create-notification-setting
Paddle::NotificationSetting.create(
  description: "Webhook for App",
  destination: "https://myapp.com/webhook",
  type: "webhook",
  subscribed_events: [
    "subscription.activated",
    "transaction.completed"
  ]
)

# Update a notification setting
# https://developer.paddle.com/api-reference/notification-settings/update-notification-setting
setting.update(subscribed_events: %w[subscription.activated transaction.completed transaction.billed])
# or
Paddle::NotificationSetting.update(id: "ntfset_abc123",
  subscribed_events: [
    "subscription.activated",
    "transaction.completed",
    "transaction.billed"
  ]
)

# Delete a notification setting
Paddle::NotificationSetting.delete(id: "ntfset_abc123")
```

### Notifications

```ruby
# List all notifications
Paddle::Notification.list
Paddle::Notification.list(notification_setting_id: "ntfset_abc123")
Paddle::Notification.list(status: "delivered")
Paddle::Notification.list(status: "failed")

# Retrieve a notification
Paddle::Notification.retrieve(id: "ntf_abc123")

# Replay a notification
# Creates a new notification for the same event. Only delivered or failed notifications
# with an origin of "event" can be replayed. Returns the new notification_id
# https://developer.paddle.com/api-reference/notifications/replay-notification
Paddle::Notification.replay(id: "ntf_abc123")
#=> #<Paddle::Notification notification_id="ntf_abc456">

# List all logs for a notification
# https://developer.paddle.com/api-reference/notifications/list-notification-logs
Paddle::Notification.logs(id: "ntf_abc123")
```

### Reports

```ruby
# List all reports
Paddle::Report.list

# Retrieve a report
Paddle::Report.retrieve(id: "rpt_abc123")

# Get CSV download link for a report
# Returns a raw URL. This URL is not permanent and will expire.
# https://developer.paddle.com/api-reference/reports/get-report-csv
Paddle::Report.csv(id: "rpt_abc123")

# Create a Report
# https://developer.paddle.com/api-reference/reports/create-report
Paddle::Report.create(
  type: "transactions",
  filters: [
    {name: "updated_at", operator: "lt", value: "2024-04-30"},
    {name: "updated_at", operator: "gte", value: "2024-04-01"}
  ]
)
```

### Webhook Simulation Types

Retrieves a list of Simulation Types - <https://developer.paddle.com/api-reference/simulation-types/overview>

```ruby
Paddle::SimulationType.list
```

### Webhook Simulations

```ruby
# List all simulations
Paddle::Simulation.list
Paddle::Simulation.list(status: "archived")
Paddle::Simulation.list(notification_setting_id: "nftset_abc123")

# Create a simulation
# https://developer.paddle.com/api-reference/simulations/create-simulation
Paddle::Simulation.create(setting_id: "ntfset_abc123", name: "Customer Create", type: "customer.completed")
Paddle::Simulation.create(setting_id: "ntfset_abc123", name: "Subscription Created", type: "subscription_creation")

# Retrieve a simulation
Paddle::Simulation.retrieve(id: "ntfsim_abc123")

# Update a simulation
# https://developer.paddle.com/api-reference/simulations/update-simulation
Paddle::Simulation.update(id: "ntfsim_abc123", name: "Simulation 2")
Paddle::Simulation.update(id: "ntfsim_abc123", status: "archived")

# List all simulation runs
Paddle::Simulation.runs(id: "ntfsim_abc123")
Paddle::Simulation.runs(id: "ntfsim_abc123", per_page: 10, include: "events")

# Create a simulation run
# https://developer.paddle.com/api-reference/simulations/create-simulation-run
Paddle::SimulationRun.create(simulation_id: "ntfsim_abc123")

# Retrieve a simulation run
Paddle::SimulationRun.retrieve(simulation_id: "ntfsim_abc123", id: "ntfsimrun_abc123")

# List all simulation run events
Paddle::SimulationRun.events(simulation_id: "ntfsim_abc123", id: "ntfsimrun_abc123")
Paddle::SimulationRun.events(simulation_id: "ntfsim_abc123", id: "ntfsimrun_abc123", per_page: 10)

# Replay a simulation run event
# https://developer.paddle.com/api-reference/simulations/replay-simulation-run-event
Paddle::SimulationRunEvent.replay(simulation_id: "ntfsim_abc123", run_id: "ntfsimrun_abc123", id: "ntfsimevt_abc123")
```

### Client Tokens

```ruby
# List all Client Tokens
# https://developer.paddle.com/api-reference/client-tokens/list-client-tokens
Paddle::ClientToken.list

# Create a Client Token
# https://developer.paddle.com/api-reference/client-tokens/create-client-token
Paddle::ClientToken.create name: "My Token"

# Get a Client Token
# https://developer.paddle.com/api-reference/client-tokens/get-client-token
Paddle::ClientToken.retrieve id: "ctkn_abc123"

# Update a Client Token
# https://developer.paddle.com/api-reference/client-tokens/update-client-token
Paddle::ClientToken.update id: "ctkn_abc123", status: "revoked"
```

## Classic API

For accessing the Paddle Classic API

### Set Client Details

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

### Plans

```ruby
# Retrieves a list of Plans
@client.plans.list
```

### Subscription Users

```ruby
# List all users subscribed to any plan
@client.users.list
@client.users.list(subscription_id: "abc123")
@client.users.list(plan_id: "abc123")
@client.users.list(state: "active")
@client.users.list(state: "deleted")

# Update a user's subscription
# https://developer.paddle.com/api-reference/e3872343dfbba-update-user
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

## Contributing

Bug reports and pull requests are welcome on GitHub at <https://github.com/deanpcmad/paddle>.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
