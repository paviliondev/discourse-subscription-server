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

  def self.subscription_map
    SiteSetting.subscription_server_subscriptions.split('|')
      .reduce({}) do |result, str|
        parts = str.split(':')

        if parts.size >= 3
          resource = parts[0]
          product_slug = parts[1]
          provider = parts[2]
          product_id = parts[3]
          domain_limit = parts[4]
          iam_group = parts[5]

          result[resource] ||= { provider: provider, products: [] }
          result[resource][:products] << {
            product_slug: product_slug,
            product_id: product_id
          }

          if domain_limit
            result[resource][:domain_limits] ||= []
            result[resource][:domain_limits] << {
              product_id: product_id,
              domain_limit: domain_limit.to_i
            }
          end

          if iam_group
            result[resource][:iam] ||= {}
            result[resource][:iam][product_id] = iam_group
          end
        end

        result
      end
  end

  def self.product_map
    result = {}
    subscription_map.each do |resource, attrs|
      result[resource] = attrs[:products]
    end
    result
  end
end
