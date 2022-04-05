# frozen_string_literal: true

class SubscriptionServer::UserSubscriptions
  SCOPE ||= "discourse-subscription-server:user_subscription"

  cattr_accessor :providers do
    {
      stripe: "SubscriptionServer::Stripe"
    }
  end

  attr_reader :user
  attr_accessor :subscriptions,
                :errors

  def initialize(user)
    @user = user
    @subscriptions = []
    @errors = []
  end

  def self.add_provider(name, class_name)
    providers[name] = class_name
  end

  def self.remove_provider(name)
    providers.delete(name)
  end

  def load(resources)
    return unless resources.present?

    resources.each do |resource|
      sub_atts = subscriptions_map[resource]
      next handle_failure(resource, "no subscription found for #{resource}") unless sub_atts.present?

      klass = providers[sub_atts[:provider].to_sym]
      next handle_failure(resource, "#{sub_atts[:provider]} is not a supported provider") unless klass

      provider = klass.constantize.new(@user)
      next handle_failure(resource, "#{provider.name} is not installed") unless provider.installed?
      next handle_failure(resource, "failed to setup #{provider.name}") unless provider.setup

      resource_subscriptions = provider.subscriptions(sub_atts[:provider_ids], resource)
      next handle_failure(resource, "no subscriptions found for #{resource}") unless resource_subscriptions.any?

      subscriptions.push(*resource_subscriptions)
    end

    @subscriptions = subscriptions
  end

  protected

  def subscriptions_map
    @subscriptions_map ||= begin
      SiteSetting.subscription_server_subscriptions.split('|')
        .reduce({}) do |result, str|
          parts = str.split(':')
          if parts.size === 3
            result[parts[0]] ||= { provider: parts[1], provider_ids: [] }
            result[parts[0]][:provider_ids] << parts[2]
          end
          result
        end
    end
  end

  def handle_failure(resource, message)
    full_message = "Failed to load #{resource} subscriptions for #{@user.username}: #{message}"
    Rails.logger.warn(full_message)
    @errors << full_message
    false
  end
end
