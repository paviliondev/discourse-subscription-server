# frozen_string_literal: true

# name: stripe_plugin
# about: Fixture plugin stripe provider
# version: 1.0

module ::Stripe
  extend self

  PRODUCT_ID ||= "prod_CBTNpi3fqWWkq0"
  PRODUCT_NAME ||= "Business Subscription"
  PRICE_ID ||= "price_id"
  PRICE_NAME ||= "yearly"

  attr_accessor :api_key

  class Customer
    cattr_accessor :has_subscription

    def self.list(email: nil, expand: nil)
      stripe_path = "#{Rails.root}/plugins/discourse-subscription-server/spec/fixtures/providers/stripe"
      customer_list = JSON.parse(::File.open("#{stripe_path}/customer_list.json"))
      customer_list["data"][0]["email"] = email
      customer_list["data"][0]["subscriptions"] ||= {}
      customer_list["data"][0]["subscriptions"]["data"] ||= []

      if has_subscription
        subscription = JSON.parse(::File.open("#{stripe_path}/subscription.json"))
        subscription["items"]["data"][0]["price"]["product"] = PRODUCT_ID
        subscription["items"]["data"][0]["price"]["id"] = PRICE_ID
        subscription["items"]["data"][0]["price"]["nickname"] = PRICE_NAME
        customer_list["data"][0]["subscriptions"]["data"] << subscription
      end

      customer_list.deep_symbolize_keys
    end
  end

  class Product
    def self.retrieve(product_id)
      stripe_path = "#{Rails.root}/plugins/discourse-subscription-server/spec/fixtures/providers/stripe"
      product = JSON.parse(::File.open("#{stripe_path}/product.json"))
      product["id"] = product_id
      product["name"] = PRODUCT_NAME
      product.deep_symbolize_keys
    end
  end
end
