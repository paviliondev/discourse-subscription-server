# frozen_string_literal: true

class SubscriptionServer::UserSubscriptionsController < ApplicationController
  skip_before_action :check_xhr, :preload_json, :verify_authenticity_token
  before_action :ensure_can_access

  def index
    user_subs = SubscriptionServer::UserSubscriptions.new(current_user)
    user_subs.load(resources)

    if user_subs.subscriptions.any?
      render json: success_json.merge(subscriptions: serialize_data(user_subs.subscriptions, SubscriptionServer::SubscriptionSerializer))
    else
      render json: failed_json.merge(error: user_subs.errors.join('\n')), status: 404
    end
  end

  protected

  def ensure_can_access
    unless is_user_api? && current_user.present? && user_api_key_has_required_scope?
      raise Discourse::InvalidAccess.new('user subscriptions requires authentication with user api')
    end
  end

  def resources
    resources = params.permit(resources: [])

    unless resources["resources"]
      raise Discourse::InvalidParameters.new(:resources)
    end

    resources["resources"]
  end

  def user_api_key_has_required_scope?
    user_api_key = request.env[Auth::DefaultCurrentUserProvider::USER_API_KEY]
    hashed_user_api_key = ApiKey.hash_key(user_api_key)
    user_api_key_record = UserApiKey.active.where(key_hash: hashed_user_api_key).first
    user_api_key_record&.scopes&.any? { |scope| scope.name == SubscriptionServer::UserSubscriptions::SCOPE }
  end
end
