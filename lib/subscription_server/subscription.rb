# frozen_string_literal: true
class SubscriptionServer::Subscription
  include ActiveModel::Serialization

  attr_reader :resource,
              :product_id,
              :product_name,
              :price_id,
              :price_name

  def initialize(resource: nil, product_id: nil, product_name: nil, price_id: nil, price_name: nil)
    @resource = resource
    @product_id = product_id
    @product_name = product_name
    @price_id = price_id
    @price_name = price_name
  end

  def self.map
    SiteSetting.subscription_server_subscriptions.split('|')
      .reduce({}) do |result, str|
        parts = str.split(':')

        if parts.size >= 3
          resource = parts[0]
          provider = parts[1]
          product_id = parts[2]
          domain_limit = parts[3]

          result[resource] ||= { provider: provider, product_ids: [] }
          result[resource][:product_ids] << product_id

          if domain_limit
            result[resource][:domain_limits] ||= []
            result[resource][:domain_limits] << { product_id: product_id, domain_limit: domain_limit.to_i }
          end
        end

        result
      end
  end
end
