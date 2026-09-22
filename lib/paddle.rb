# frozen_string_literal: true

require "faraday"

require_relative "paddle/version"

module Paddle
  autoload :Configuration, "paddle/configuration"
  autoload :Client, "paddle/client"
  autoload :Collection, "paddle/collection"
  autoload :Error, "paddle/error"
  autoload :Errors, "paddle/error_generator"
  autoload :ErrorGenerator, "paddle/error_generator"
  autoload :ErrorFactory, "paddle/error_generator"

  autoload :Object, "paddle/object"
  autoload :Webhook, "paddle/webhook"

  class << self
    attr_writer :config
  end

  # Configures the global config, even inside a with_config block
  def self.configure
    yield(global_config) if block_given?
  end

  # The config for the current request: the with_config override if there is one, or the global config
  def self.config
    Fiber[:paddle_config] || global_config
  end

  def self.global_config
    @config ||= Paddle::Configuration.new
  end

  # Uses a different API key, environment or version for everything in the block, e.g. to make
  # requests for another Paddle account. The override is stored in fiber storage, so it only
  # applies to the current thread or fiber, and to threads and fibers started inside the block.
  #
  #   Paddle.with_config(api_key: account.paddle_api_key) do
  #     Paddle::Subscription.list
  #   end
  def self.with_config(**options)
    previous = Fiber[:paddle_config]
    Fiber[:paddle_config] = config.merge(**options)
    yield
  ensure
    Fiber[:paddle_config] = previous
  end

  # Load Billing APIs
  autoload :Product, "paddle/models/product"
  autoload :Price, "paddle/models/price"
  autoload :PricingPreview, "paddle/models/pricing_preview"
  autoload :Discount, "paddle/models/discount"
  autoload :DiscountGroup, "paddle/models/discount_group"
  autoload :Customer, "paddle/models/customer"
  autoload :Address, "paddle/models/address"
  autoload :Business, "paddle/models/business"
  autoload :Transaction, "paddle/models/transaction"
  autoload :Subscription, "paddle/models/subscription"
  autoload :Adjustment, "paddle/models/adjustment"
  autoload :EventType, "paddle/models/event_type"
  autoload :Event, "paddle/models/event"
  autoload :NotificationSetting, "paddle/models/notification_setting"
  autoload :Notification, "paddle/models/notification"
  autoload :Report, "paddle/models/report"
  autoload :SimulationType, "paddle/models/simulation_type"
  autoload :Simulation, "paddle/models/simulation"
  autoload :SimulationRun, "paddle/models/simulation_run"
  autoload :SimulationRunEvent, "paddle/models/simulation_run_event"
  autoload :PortalSession, "paddle/models/portal_session"
  autoload :PaymentMethod, "paddle/models/payment_method"
  autoload :ClientToken, "paddle/models/client_token"
  autoload :Metric, "paddle/models/metric"
  autoload :ExploreEntity, "paddle/models/explore_entity"
  autoload :ExploreResult, "paddle/models/explore_result"

  autoload :NotificationLog, "paddle/models/notification_log"
  autoload :CreditBalance, "paddle/models/credit_balance"
  autoload :CustomerAuthToken, "paddle/models/customer_auth_token"
  autoload :SubscriptionHistory, "paddle/models/subscription_history"

  # Load Classic APIs
  module Classic
    autoload :Client, "paddle/classic/client"
    autoload :Collection, "paddle/classic/collection"
    autoload :Resource, "paddle/classic/resource"
    autoload :Error, "paddle/classic/error"

    autoload :PlansResource, "paddle/classic/resources/plans"
    autoload :CouponsResource, "paddle/classic/resources/coupons"
    autoload :ProductsResource, "paddle/classic/resources/products"
    autoload :LicensesResource, "paddle/classic/resources/licenses"
    autoload :PayLinksResource, "paddle/classic/resources/pay_links"
    autoload :TransactionsResource, "paddle/classic/resources/transactions"
    autoload :PaymentsResource, "paddle/classic/resources/payments"
    autoload :UsersResource, "paddle/classic/resources/users"
    autoload :WebhooksResource, "paddle/classic/resources/webhooks"
    autoload :ModifiersResource, "paddle/classic/resources/modifiers"
    autoload :ChargesResource, "paddle/classic/resources/charges"

    autoload :Plan, "paddle/classic/objects/plan"
    autoload :Coupon, "paddle/classic/objects/coupon"
    autoload :Product, "paddle/classic/objects/product"
    autoload :License, "paddle/classic/objects/license"
    autoload :PayLink, "paddle/classic/objects/pay_link"
    autoload :Transaction, "paddle/classic/objects/transaction"
    autoload :Payment, "paddle/classic/objects/payment"
    autoload :PaymentRefund, "paddle/classic/objects/payment_refund"
    autoload :User, "paddle/classic/objects/user"
    autoload :Webhook, "paddle/classic/objects/webhook"
    autoload :Modifier, "paddle/classic/objects/modifier"
    autoload :Charge, "paddle/classic/objects/charge"
  end
end
