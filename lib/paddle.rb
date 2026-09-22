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

  class << self
    attr_writer :config
  end

  def self.configure
    yield(config) if block_given?
  end

  def self.config
    @config ||= Paddle::Configuration.new
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
