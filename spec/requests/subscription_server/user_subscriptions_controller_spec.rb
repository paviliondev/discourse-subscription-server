# frozen_string_literal: true

describe SubscriptionServer::UserSubscriptionsController do
  let(:user) { Fabricate(:user) }
  let(:subscription_user_api_key) { Fabricate(:subscription_server_user_api_key, user: user) }
  let(:readonly_user_api_key) { Fabricate(:readonly_user_api_key, user: user) }
  let(:provider) { "stripe" }
  let(:resource_name) { "custom_wizard" }
  let(:client) { "https://demo.pavilion.tech" }

  it "requires a user authenticated with a user api key" do
    get "/subscription-server/user-subscriptions"
    expect(response.status).to eq(403)

    sign_in(user)
    get "/subscription-server/user-subscriptions"
    expect(response.status).to eq(403)
  end

  it "requires a user authenticated with a user api key with the user_subscriptions scope" do
    get "/subscription-server/user-subscriptions", headers: { HTTP_USER_API_KEY: readonly_user_api_key.key }
    expect(response.status).to eq(403)
  end

  context "when authenticated" do
    def headers
      { HTTP_USER_API_KEY: subscription_user_api_key.key, ORIGIN: client }
    end

    describe "#index" do
      let!(:subscription) {
        SubscriptionServer::Subscription.new(
          resource: resource_name,
          product_id: "prod_CBTNpi3fqWWkq0",
          product_name: "Business Subscription",
          price_id: "price_id",
          price_name: "yearly"
        )
      }

      it "requires a request origin" do
        get "/subscription-server/user-subscriptions", headers: headers.except(:ORIGIN)
        expect(response.status).to eq(400)
      end

      it "returns subscription list if SubscriptionServer::UserSubscriptions loads subcriptions" do
        SubscriptionServer::UserSubscriptions.any_instance.stubs(:subscriptions).returns([subscription])
        get "/subscription-server/user-subscriptions", headers: headers, params: { resources: [resource_name] }
        expect(response.status).to eq(200)
        expect(response.parsed_body).to eq(
          {
            success: "OK",
            subscriptions: ActiveModel::ArraySerializer.new(
              [subscription],
              each_serializer: SubscriptionServer::UserSubscriptionSerializer
            ).as_json,
            resources: []
          }.as_json
        )
      end

      it "returns a blank array if SubscriptionServer::UserSubscriptions does not load any subscriptions" do
        get "/subscription-server/user-subscriptions", headers: headers, params: { resources: [resource_name] }
        expect(response.status).to eq(200)
        expect(response.parsed_body).to eq(
          {
            success: "OK",
            subscriptions: [].as_json,
            resources: []
          }.as_json
        )
      end

      context "with subscription resources" do
        let!(:resource) {
          SubscriptionServer::UserResource.new(
            resource_name: resource_name,
            iam_user_name: user.username,
            iam_access_key_id: '12345',
            iam_secret_access_key: '23rn2o3irn2',
            iam_key_updated_at: Time.now
          )
        }

        before do
          SubscriptionServer::UserSubscriptions.stubs(:load).returns([subscription])
          SubscriptionServer::UserResource.stubs(:list).returns([resource])
        end

        it "returns valid resources" do
          get "/subscription-server/user-subscriptions", headers: headers, params: { resources: [resource_name] }
          expect(response.status).to eq(200)
          expect(response.parsed_body).to eq(
            {
              success: "OK",
              subscriptions: ActiveModel::ArraySerializer.new(
                [subscription],
                each_serializer: SubscriptionServer::UserSubscriptionSerializer
              ).as_json,
              resources: ActiveModel::ArraySerializer.new(
                [resource],
                each_serializer: SubscriptionServer::UserResourceSerializer
              ).as_json
            }.as_json
          )
        end
      end
    end
  end
end
