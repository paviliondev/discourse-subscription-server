# frozen_string_literal: true

describe SubscriptionServer::UserResource do
  let!(:user1) { Fabricate(:user) }
  let!(:user2) { Fabricate(:user) }

  describe "#list" do
    context "with a resource with iam" do
      let(:subscription1) {
        SubscriptionServer::Subscription.new(
          resource: 'discourse-events',
          product_id: "prod_CBTNpi3fqWWkq0",
          product_name: "Business Subscription",
          price_id: "1234567",
          price_name: "yearly"
        )
      }
      let(:subscription2) {
        SubscriptionServer::Subscription.new(
          resource: 'discourse-events',
          product_id: "prod_CBTNpi3fqWWkq1",
          product_name: "Community Subscription",
          price_id: "1234568",
          price_name: "yearly"
        )
      }

      before do
        SiteSetting.subscription_server_iam_access_key = "12345"
        SiteSetting.subscription_server_iam_secret_access_key = "23l42l3nk423o2"
        SiteSetting.subscription_server_subscriptions = "discourse-events:business:stripe:prod_CBTNpi3fqWWkq0:1:discourse_events_business|discourse-events:community:stripe:prod_CBTNpi3fqWWkq1:1:discourse_events_community"
      end

      it "returns the right user resources" do
        result = described_class.list(user1.id, [subscription1])
        expect(result[0]).to be_present
        expect(result[0].resource_name).to eq("discourse-events")
        expect(result[0].iam_group).to eq('discourse_events_business')
        expect(result[0].iam_user_name).to be_present
        expect(result[0].iam_access_key_id).to be_present
        expect(result[0].iam_secret_access_key).to be_present
        expect(result[0].iam_key_updated_at).to be_present

        result = described_class.list(user2.id, [subscription2])
        expect(result[0]).to be_present
        expect(result[0].iam_group).to eq('discourse_events_community')
      end
    end

    context "with a resource without iam" do
      let(:subscription) {
        SubscriptionServer::Subscription.new(
          resource: 'discourse-custom-wizard',
          product_id: "prod_CBTNpi3fqWWkq0",
          product_name: "Business Subscription",
          price_id: "1234567",
          price_name: "yearly"
        )
      }

      before do
        SiteSetting.subscription_server_iam_access_key = "12345"
        SiteSetting.subscription_server_iam_secret_access_key = "23l42l3nk423o2"
        SiteSetting.subscription_server_subscriptions = "discourse-custom-wizard:business:stripe:prod_CBTNpi3fqWWkq0:1"
      end

      it "returns the right user resources" do
        result = described_class.list(user1.id, [subscription])
        expect(result[0]).to be_present
        expect(result[0].resource_name).to eq("discourse-custom-wizard")
        expect(result[0].iam_user_name).not_to be_present
        expect(result[0].iam_access_key_id).not_to be_present
        expect(result[0].iam_secret_access_key).not_to be_present
        expect(result[0].iam_key_updated_at).not_to be_present
      end
    end
  end
end
