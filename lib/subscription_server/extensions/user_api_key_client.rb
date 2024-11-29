# frozen_string_literal: true

module SubscriptionServer::Extensions::UserApiKeyClient
  def invalid_auth_redirect_for_subscriptions?(auth_redirect, request)
    ## Allow any auth redirect if the scope is only user subscriptions scope.
    return false if request.params[:scopes] == SubscriptionServer::UserSubscriptions::SCOPE

    invalid_auth_redirect?(auth_redirect, perform_check: true)
  end

  def invalid_auth_redirect?(auth_redirect, client: nil, perform_check: false)
    return false unless perform_check
    super(auth_redirect)
  end
end
