# frozen_string_literal: true

class SubscriptionServer::Stripe < SubscriptionServer::Provider
  def name
    'stripe'
  end

  def installed?
    defined?(Stripe) == 'constant' && Stripe.class == Module
  end

  def discourse_subscriptions_installed?
    defined?(DiscourseSubscriptions) == 'constant' && DiscourseSubscriptions.class == Module
  end

  def setup
    if installed? && discourse_subscriptions_installed?
      ::Stripe.api_key = SiteSetting.discourse_subscriptions_secret_key
    end

    ::Stripe.api_key.present?
  end

  def subscriptions(product_ids, resource_name)
    customers = ::Stripe::Customer.list(email: @user.email, expand: ['data.subscriptions'])
    subscriptions = customers[:data].map { |c| c[:subscriptions][:data] }.flatten(1)
    return [] if subscriptions.none?

    subscriptions.reduce([]) do |result, sub|
      sub_hash = sub.to_h
      price = sub_hash[:items][:data][0][:price]

      if product_ids.include?(price[:product]) && sub_hash[:status] == 'active'
        product = ::Stripe::Product.retrieve(price[:product])
        subscription = SubscriptionServer::Subscription.new(
          resource: resource_name,
          product_id: product[:id],
          product_name: product[:name],
          price_id: price[:id],
          price_name: price[:nickname]
        )
        result.push(subscription)
      end

      result
    end
  end

  def self.discourse_subscriptions_installed?
    new.discourse_subscriptions_installed?
  end
end
