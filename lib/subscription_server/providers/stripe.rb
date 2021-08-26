# frozen_string_literal: true

class SubscriptionServer::Stripe < SubscriptionServer::Provider
  def name
    'stripe'
  end

  def installed
    defined?(Stripe) == 'constant' && Stripe.class == Module
  end

  def setup
    if SiteSetting.respond_to?("discourse_subscriptions_secret_key")
      ::Stripe.api_key = SiteSetting.discourse_subscriptions_secret_key
    end
    ::Stripe.api_key.present?
  end

  def load(provider_id)
    customers = ::Stripe::Customer.list(email: @user.email, expand: ['data.subscriptions'])
    subscriptions = customers[:data].map { |c| c[:subscriptions][:data] }.flatten(1)
    return [] unless subscriptions.any?

    subscriptions.reduce([]) do |result, subscription|
      subscripion = subscripion.to_h
      price = subscription[:items][:data][0][:price]

      if price[:product] == provider_id
        SubscriptionServer::Subscription.new(
          product_id: price[:product],
          price_id: price[:id],
          price_nickname: price[:nickname]
        )
        result.push(subscripion)
      end

      result
    end
  end
end
