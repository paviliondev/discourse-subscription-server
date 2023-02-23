# frozen_string_literal: true

class SubscriptionServer::UserSubscriptions
  SCOPE ||= "discourse-subscription-server:user_subscription"
  DOMAINS_KEY_PREFIX ||= "subscription_domains"

  cattr_accessor :providers do
    {
      stripe: "SubscriptionServer::Stripe"
    }
  end

  attr_reader :user,
              :domain

  attr_accessor :subscriptions,
                :errors

  def initialize(user = nil, domain = nil)
    @user = user
    @subscriptions = []
    @errors = []
    @domain = domain
  end

  def self.add_provider(name, class_name)
    providers[name] = class_name
  end

  def self.remove_provider(name)
    providers.delete(name)
  end

  def load(resources = nil)
    return unless resources.present? && @user.present? && @domain.present?

    resources.each do |resource|
      sub_atts = SubscriptionServer::Subscription.subscription_map[resource]
      next handle_failure(resource, "no subscription found for #{resource}") unless sub_atts.present?

      klass = providers[sub_atts[:provider].to_sym]
      next handle_failure(resource, "#{sub_atts[:provider]} is not a supported provider") unless klass

      provider = klass.constantize.new(@user)
      next handle_failure(resource, "#{provider.name} is not installed") unless provider.installed?
      next handle_failure(resource, "failed to setup #{provider.name}") unless provider.setup

      product_ids = sub_atts[:products].map { |p| p[:product_id] }
      resource_subscriptions = provider.subscriptions(product_ids, resource)
      next handle_failure(resource, "no subscriptions found for #{resource}") unless resource_subscriptions.any?

      product_ids = resource_subscriptions.map(&:product_id)

      if reached_resource_domain_limit(resource, sub_atts, provider.name, product_ids)
        next handle_failure(resource, "domain limit reached for #{resource}")
      end

      product_ids.each do |product_id|
        @user.add_subscription_product_domain(@domain, resource, provider.name, product_id)
      end

      subscriptions.push(*resource_subscriptions)
    end

    @subscriptions = subscriptions
  end

  protected

  def handle_failure(resource, message)
    full_message = "Failed to load #{resource} subscriptions for #{@user.username}: #{message}"
    Rails.logger.warn(full_message)
    @errors << full_message
    false
  end

  def reached_resource_domain_limit(resource, subscription_attrs, provider_name, product_ids)
    return false unless subscription_attrs[:domain_limits].present?

    resource_domains = []
    resource_domain_limit = subscription_attrs[:domain_limits]
      .select { |limit| product_ids.include?(limit[:product_id]) }
      .sum { |limit| limit[:domain_limit] }

    product_ids.each do |product_id|
      product_domains = @user.subscription_product_domains(resource, provider_name, product_id)
      resource_domains.concat product_domains
    end

    return false if resource_domains.include?(@domain)

    resource_domains.size >= resource_domain_limit
  end
end
