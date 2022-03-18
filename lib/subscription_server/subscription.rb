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
end
