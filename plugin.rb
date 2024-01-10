# frozen_string_literal: true

# name: discourse-subscription-server
# about: Use Discourse as a subscription server
# version: 0.3.3
# url: https://github.com/paviliondev/discourse-subscription-server
# authors: Angus McLeod
# contact_emails: development@pavilion.tech

enabled_site_setting :subscription_server_enabled

DiscourseEvent.on(:after_plugin_activation) do
  sorted_pugins = Discourse.plugins.sort_by do |p|
    p&.name == 'discourse-subscription-server' ? 1 : 0
  end
  Discourse.instance_variable_set(:@plugins, sorted_pugins)
end

after_initialize do
  %w[
    ../lib/subscription_server/engine.rb
    ../lib/subscription_server/subscription.rb
    ../lib/subscription_server/provider.rb
    ../lib/subscription_server/message.rb
    ../lib/subscription_server/providers/stripe.rb
    ../lib/subscription_server/user_subscriptions.rb
    ../lib/subscription_server/extensions/user_api_key.rb
    ../lib/subscription_server/extensions/user_api_keys_controller.rb
    ../config/routes.rb
    ../app/controllers/subscription_server/user_subscriptions_controller.rb
    ../app/controllers/subscription_server/user_authorizations_controller.rb
    ../app/controllers/subscription_server/messages_controller.rb
    ../app/controllers/subscription_server/server_controller.rb
    ../app/serializers/subscription_server/message_serializer.rb
    ../app/serializers/subscription_server/subscription_serializer.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end

  UserApiKey.singleton_class.prepend SubscriptionServer::Extensions::UserApiKey
  UserApiKeysController.prepend SubscriptionServer::Extensions::UserApiKeysController

  add_user_api_key_scope(:user_subscription,
    methods: :get,
    actions: "subscription_server/user_subscriptions#index",
    params: :client_name
  )

  add_to_class(:user, :subscription_product_domain_key) do |resource_name, provider_name, product_id|
    "#{SubscriptionServer::UserSubscriptions::DOMAINS_KEY_PREFIX}:#{resource_name}:#{provider_name}:#{product_id}"
  end

  add_to_class(:user, :add_subscription_product_domain) do |domain, resource_name, provider_name, product_id|
    key = subscription_product_domain_key(resource_name, provider_name, product_id)
    value_str = (custom_fields[key] || "")
    value_arr = value_str.split('|')
    value_arr << domain unless value_arr.include?(domain)
    custom_fields[key] = value_arr.join('|')

    save_custom_fields(true)
  end

  add_to_class(:user, :remove_subscription_product_domain) do |domain, resource_name, provider_name, product_id|
    key = subscription_product_domain_key(resource_name, provider_name, product_id)
    value_str = (custom_fields[key] || "")
    value_arr = value_str.split('|')
    value_arr = value_arr.reject { |d| d === domain }
    custom_fields[key] = value_arr.join('|')

    save_custom_fields(true)
  end

  add_to_class(:user, :remove_subscription_domain) do |domain|
    self._custom_fields.where(
      "name LIKE '#{SubscriptionServer::UserSubscriptions::DOMAINS_KEY_PREFIX}%'"
    ).each do |field|
      value_arr = field.value.split('|')
      value_arr = value_arr.reject { |d| d === domain }
      field.value = value_arr.join('|')
      field.save!
    end
  end

  add_to_class(:user, :subscription_product_domains) do |resource_name, provider_name, product_id|
    key = subscription_product_domain_key(resource_name, provider_name, product_id)
    product_domains = custom_fields[key]
    (product_domains || "").split('|').uniq
  end

  add_to_class(:user, :subscription_domains) do
    subscriptions_map = SubscriptionServer::Subscription.subscription_map
    subscription_domains = {}

    custom_fields
      .select { |key, _| key.include?(SubscriptionServer::UserSubscriptions::DOMAINS_KEY_PREFIX) }
      .each do |key, value|
        key_parts = key.split(':')

        subscription_domains[key_parts[1]] ||= { products: [], domains: [] }
        subscription_domains[key_parts[1]][:products] << key_parts[3]
        subscription_domains[key_parts[1]][:domains].concat value.split('|')
      end

    subscription_domains.each do |resource, data|
      data[:domain_limit] = subscriptions_map[resource][:domain_limits]
        .select { |limit| data[:products].include?(limit[:product_id]) }
        .sum { |limit| limit[:domain_limit] }
    end

    subscription_domains.reduce([]) do |result, (resource, data)|
      data[:resource] = resource
      result << data
      result
    end
  end

  add_to_serializer(:user, :subscription_domains) { user.subscription_domains }

  if SubscriptionServer::Stripe.discourse_subscriptions_installed?
    %w[
      ../extensions/discourse_subscriptions_coupons_controller_extension.rb
      ../extensions/discourse_subscriptions_products_controller_extension.rb
      ../extensions/discourse_subscriptions_subscriber_controller_extension.rb
    ].each do |path|
      load File.expand_path(path, __FILE__)
    end
    DiscourseSubscriptions::SubscribeController.prepend DiscourseSubscriptionsSubscribeControllerExtension
    DiscourseSubscriptions::Admin::CouponsController.prepend DiscourseSubscriptionsCouponsControllerExtension
    DiscourseSubscriptions::Admin::ProductsController.prepend DiscourseSubscriptionsProductsControllerExtension

    require 'csv'
    module ::DiscourseSubscriptions
      def self.class_update_subscriptions_from_csv(path)
        rows = CSV.read(path)
        return unless rows.present?

        rows.each do |row|
          DiscourseSubscriptions::Subscription
            .joins(:customer)
            .where("discourse_subscriptions_customers.customer_id = :customer_id AND discourse_subscriptions_subscriptions.external_id = :subscription_id",
              customer_id: row[0].strip,
              subscription_id: row[1].strip
            ).update_all(
              external_id: row[2].strip
            )
        end
      end
    end
  end
end
