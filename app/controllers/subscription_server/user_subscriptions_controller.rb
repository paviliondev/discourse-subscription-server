class SubscriptionServer::UserSubscriptionsController < ApplicationController
  skip_before_action :check_xhr, :preload_json, :verify_authenticity_token
  before_action :ensure_user_api_request

  def index
    user_subscriptions = SubscriptionServer::UserSubscriptions.new(current_user)
    user_subscriptions.load(user_subscription_params.to_h)

    if user_subscriptions.any?
      render json: success_json.merge(subscriptions: user_subscriptions.info)
    else
      render json: failed_json, status: 404
    end
  end

  protected

  def ensure_user_api_request
    raise Discourse::InvalidAccess.new('only available via user api') if !is_user_api?
  end

  def user_subscription_params
    params.permit(:client_name, :subscription_type)
  end
end