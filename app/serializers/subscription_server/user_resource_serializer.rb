# frozen_string_literal: true

class SubscriptionServer::UserResourceSerializer < ApplicationSerializer
  attributes :resource_name,
             :iam_access_key_id,
             :iam_secret_access_key
end
