module SubscriptionServer::Stripe
  attr_accessor :api_key

  def stripe_installed
    defined?(Stripe) == 'constant' && Stripe.class == Module  
  end

  def stripe_initialize    
    ::Stripe.api_key = stripe_retrieve_api_key
    ::Stripe.api_key.present?
  end

  def stripe_load(product_id)
    subscriptions = stripe_subscriptions
    return false unless subscriptions.any?

    @subscriptions = subscriptions.reduce([]) do |result, subscription|
      subscripion = subscripion.to_h
      subscripion[:price] = subscription[:items][:data][0][:price]
      result.push(subscripion) if subscripion[:price][:product] == product_id
      result
    end  
  end

  def stripe_subscriptions
    stripe_customers[:data].map { |customer| customer[:subscriptions][:data] }.flatten(1)
  end

  def stripe_subscription_info(subscription)
    price = subscription[:price]

    SubscriptionInfo.new(
      product_id: price[:product],
      price_id: price[:id],
      price_nickname: price[:nickname]
    )
  end

  def stripe_customers
    ::Stripe::Customer.list(email: @user.email, expand: ['data.subscriptions'])
  end

  def stripe_subscription_price_keys
    
  end

  def stripe_retrieve_api_key
    if SiteSetting.respond_to?("discourse_subscriptions_secret_key")
      SiteSetting.discourse_subscriptions_secret_key
    else
      @api_key
    end
  end
end