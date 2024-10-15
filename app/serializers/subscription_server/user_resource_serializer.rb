# frozen_string_literal: true

class SubscriptionServer::UserResourceSerializer < ApplicationSerializer
  attributes :resource,
             :access_key_id,
             :secret_access_key

  def resource
    object.resource_name
  end

  def access_key_id
    object.iam_access_key_id
  end

  def secret_access_key
    object.iam_secret_access_key
  end
end
