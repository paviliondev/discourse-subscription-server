# frozen_string_literal: true

class SubscriptionServer::UserSubscriptionsController < ApplicationController
  skip_before_action :check_xhr, :preload_json, :verify_authenticity_token
  before_action :ensure_can_access

  def index
    user_subs = SubscriptionServer::UserSubscriptions.new(current_user)
    user_subs.load(user_subscription_params.to_h)

    if user_subs.subscriptions.any?
      render json: success_json.merge(subscriptions: user_subs.subscriptions.as_json)
    else
      render json: failed_json.merge(error: user_subs.error), status: 404
    end
  end

  protected

  def ensure_can_access
    unless is_user_api? && current_user.present?
      raise Discourse::InvalidAccess.new('user subscriptions requires authentication with user api')
    end
  end

  def user_subscription_params
    params.permit(:provider, :client_name)
  end
end
