# frozen_string_literal: true

# Extend this class and override all methods below
# to add a new subscriptions provider

class SubscriptionServer::Provider
  attr_reader :user

  def initialize(user = nil)
    @user = user
  end

  def name
    # Name of provider.
  end

  def installed?
    # Run first after initialization. Return true to continue.
  end

  def setup
    # Run second after initialization. Return true to continue.
  end

  def subscriptions(product_ids, resource_name)
    # Return list of SubscriptionServer::Subscription instances.
  end
end
