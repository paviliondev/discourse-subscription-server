# frozen_string_literal: true
class SubscriptionServer::Subscription
  attr_reader :product_id,
              :product_name,
              :price_id,
              :price_nickname

  def initialize(product_id: nil, price_id: nil, price_nickname: nil)
    @product_id = product_id
    @product_name = product_name
    @price_id = price_id
    @price_nickname = price_nickname
  end
end
