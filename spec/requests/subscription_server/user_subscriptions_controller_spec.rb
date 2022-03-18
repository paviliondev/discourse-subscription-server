# frozen_string_literal: true
require_relative '../../plugin_helper'

describe SubscriptionServer::UserSubscriptionsController do
  let(:user) { Fabricate(:user) }
  let(:user_api_key) { Fabricate(:subscription_server_user_api_key, user: user) }
  let(:provider) { "stripe" }
  let(:resource) { "custom_wizard" }

  it "requires a user authenticated via the user api" do
    get "/subscription-server/user-subscriptions"
    expect(response.status).to eq(403)

    sign_in(user)
    get "/subscription-server/user-subscriptions"
    expect(response.status).to eq(403)
  end

  context "authenticated" do
    def headers
      { HTTP_USER_API_KEY: user_api_key.key }
    end

    context "#index" do
      before do
        @subscription = SubscriptionServer::Subscription.new(
          resource: resource,
          product_id: "prod_CBTNpi3fqWWkq0",
          product_name: "Business Subscription",
          price_id: "price_id",
          price_name: "yearly"
        )
      end

      it "returns subscription list if SubscriptionServer::UserSubscriptions loads subcriptions" do
        SubscriptionServer::UserSubscriptions.any_instance.stubs(:subscriptions).returns([@subscription])
        get "/subscription-server/user-subscriptions", headers: headers, params: { resources: [resource] }
        expect(response.status).to eq(200)
        expect(response.parsed_body).to eq(
          {
            success: "OK",
            subscriptions: ActiveModel::ArraySerializer.new([@subscription], each_serializer: SubscriptionServer::SubscriptionSerializer).as_json
          }.as_json
        )
      end

      it "returns error if SubscriptionServer::UserSubscriptions does not load subscriptions" do
        get "/subscription-server/user-subscriptions", headers: headers, params: { resources: [resource] }
        expect(response.status).to eq(404)
      end
    end
  end
end
