# frozen_string_literal: true

class SubscriptionServer::UserSubscriptions
  attr_reader :user
  attr_accessor :subscriptions,
                :error

  def initialize(user)
    @user = user
    @subscriptions = []
    @error = nil
  end

  def self.providers
    {
      stripe: "SubscriptionServer::Stripe"
    }
  end

  def load(opts)
    klass = self.class.providers[opts[:provider].to_sym]
    return handle_failure("#{opts[:provider]} is not a supported provider") unless klass

    provider = klass.constantize.new(@user)
    return handle_failure("#{opts[:provider]} is not installed") unless provider.installed
    return handle_failure("failed to setup #{opts[:provider]}") unless provider.setup

    provider_id = clients[opts[:client_name].to_sym]
    return handle_failure("no provider found for #{opts[:client_name]}") unless provider_id

    subscriptions = provider.load(provider_id)
    return handle_failure("no subscriptions found") unless subscriptions.any?

    @subscriptions = subscriptions
  end

  protected

  def clients
    @clients ||= SiteSetting.subscription_server_client_providers.split('|')
      .reduce({}) do |result, item|
        parts = item.split(':')
        result[parts.first.to_sym] = parts.second
        result
      end
  end

  def handle_failure(message)
    full_message = "Failed to load subscriptions for #{@user.username}: #{message}"
    Rails.logger.warn(full_message)
    @error = full_message
    false
  end
end
