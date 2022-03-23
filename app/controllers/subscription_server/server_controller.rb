# frozen_string_literal: true

class SubscriptionServer::ServerController < ApplicationController
  skip_before_action :check_xhr, :preload_json, :verify_authenticity_token

  def index
    if SiteSetting.subscription_server_supplier_name.present?
      render json: success_json.merge(supplier: SiteSetting.subscription_server_supplier_name)
    else
      render json: failed_json, status: 404
    end
  end
end
