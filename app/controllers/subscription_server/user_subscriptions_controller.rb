class SubscriptionServer::UserSubscriptionsController < ApplicationController
  skip_before_action :check_xhr, :preload_json, :verify_authenticity_token
  before_action :ensure_can_access

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

  def ensure_can_access
    unless is_user_api? && current_user.present?
      raise Discourse::InvalidAccess.new('only available via user api')
    end
  end

  def user_subscription_params
    params.permit(:subscription_type, :client_name)
  end
end