# frozen_string_literal: true

class SubscriptionServer::UserSubscriptionSerializer < ApplicationSerializer
  attributes :resource,
             :product_id,
             :product_name,
             :price_id,
             :price_name
end
