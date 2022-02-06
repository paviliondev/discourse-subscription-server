# frozen_string_literal: true
class SubscriptionServer::Subscription
  include ActiveModel::Serialization

  attr_reader :product_id,
              :product_name,
              :price_id,
              :price_nickname,
              :supplier_name

  def initialize(product_id: nil, price_id: nil, price_nickname: nil, product_name: nil)
    @product_id = product_id
    @product_name = product_name
    @price_id = price_id
    @price_nickname = price_nickname
    @supplier_name = SiteSetting.subscription_server_supplier_name
  end
end
