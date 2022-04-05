# frozen_string_literal: true

module SubscriptionServer::Extensions::UserApiKeysController
  def create
    if params.key?(:auth_redirect)
      raise Discourse::InvalidAccess if UserApiKey.invalid_auth_redirect_for_subscriptions?(params[:auth_redirect], request)
    end
    super
  end
end
