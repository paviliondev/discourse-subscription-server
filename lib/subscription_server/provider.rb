# frozen_string_literal: true

class SubscriptionServer::Provider
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def name
    # Override in provider. Name of provider.
  end

  def installed
    # Override in provider. Run first after initialization. Return true to continue.
  end

  def setup
    # Override in provider. Run second after initialization. Return true to continue.
  end

  def subscriptions(provider_id, resource_name)
    # Override in provider. Return list of SubscriptionServer::Subscription instances.
  end
end
