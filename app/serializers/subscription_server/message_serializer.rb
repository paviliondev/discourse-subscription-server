# frozen_string_literal: true

class SubscriptionServer::MessageSerializer < ApplicationSerializer
  attributes :title,
             :message,
             :type,
             :created_at,
             :expired_at

  def type
    SubscriptionServer::Message.types.key(object.type).to_s
  end
end
