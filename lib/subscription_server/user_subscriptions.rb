# frozen_string_literal: true

class SubscriptionServer::UserSubscriptions
  attr_reader :user
  attr_accessor :subscriptions,
                :errors

  def initialize(user)
    @user = user
    @subscriptions = []
    @errors = []
  end

  def self.providers
    {
      stripe: "SubscriptionServer::Stripe"
    }
  end

  def load(resources)
    resources.each do |resource|
      provider_atts = provider_map[resource]
      next handle_failure(resource, "no provider found for #{resource}") unless provider_atts.present?

      klass = self.class.providers[provider_atts[:name].to_sym]
      next handle_failure(resource, "#{provider_atts[:name]} is not a supported provider") unless klass

      provider = klass.constantize.new(@user)
      next handle_failure(resource, "#{provider.name} is not installed") unless provider.installed
      next handle_failure(resource, "failed to setup #{provider.name}") unless provider.setup

      resource_subscriptions = provider.subscriptions(provider_atts[:id], resource)
      next handle_failure(resource, "no subscriptions found for #{resource}") unless resource_subscriptions.any?

      subscriptions.push(*resource_subscriptions)
    end

    @subscriptions = subscriptions
  end

  protected

  def provider_map
    @provider_map ||= begin
      SiteSetting.subscription_server_resource_providers.split('|')
        .reduce({}) do |result, str|
          parts = str.split(':')
          if parts.size === 3
            result[parts[0]] = {
              name: parts[1],
              id: parts[2]
            }
          end
          result
        end
    end
  end

  def handle_failure(resource, message)
    full_message = "Failed to load #{resource } subscriptions for #{@user.username}: #{message}"
    Rails.logger.warn(full_message)
    @errors << full_message
    false
  end
end
