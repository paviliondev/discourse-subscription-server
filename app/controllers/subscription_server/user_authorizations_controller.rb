# frozen_string_literal: true

class SubscriptionServer::UserAuthorizationsController < ApplicationController
  before_action :ensure_logged_in

  def destroy
    params.require(:domain)
    current_user.remove_subscription_domain(params[:domain])
    render json: success_json
  end
end
