# frozen_string_literal: true
class SubscriptionServer::SubscriptionSerializer < ::ApplicationSerializer
  attributes :product_id,
             :product_name,
             :price_id,
             :price_nickname
end
