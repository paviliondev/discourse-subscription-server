# frozen_string_literal: true
require_relative '../../plugin_helper'
require 'byebug'

describe SubscriptionServer::UserSubscriptionsController do
  let(:user) { Fabricate(:user) }
  let(:user_api_key) { Fabricate(:subscription_server_user_api_key, user: user) }
  let(:provider) { "stripe" }
  let(:client_name) { "custom_wizard" }

  it "requires a user authenticated via the user api" do
    get "/subscription-server/user-subscriptions/#{provider}/#{client_name}"
    expect(response.status).to eq(403)

    sign_in(user)
    get "/subscription-server/user-subscriptions/#{provider}/#{client_name}"
    expect(response.status).to eq(403)
  end

  context "authenticated" do
    def headers
      { HTTP_USER_API_KEY: user_api_key.key }
    end

    context "#index" do
      before do
        @subscription = SubscriptionServer::Subscription.new(
          product_id: "prod_CBTNpi3fqWWkq0",
          price_id: "price_id",
          price_nickname: "business"
        )
      end

      it "returns subscription list if SubscriptionServer::UserSubscriptions loads subcriptions" do
        SubscriptionServer::UserSubscriptions.any_instance.stubs(:subscriptions).returns([@subscription])
        get "/subscription-server/user-subscriptions/#{provider}/#{client_name}", headers: headers
        expect(response.status).to eq(200)
        expect(response.parsed_body).to eq(
          {
            success: "OK",
            subscriptions: [@subscription.as_json]
          }.as_json
        )
      end

      it "returns error if SubscriptionServer::UserSubscriptions does not load subscriptions" do
        get "/subscription-server/user-subscriptions/#{provider}/#{client_name}", headers: headers
        expect(response.status).to eq(404)
      end
    end
  end
end
