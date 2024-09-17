# frozen_string_literal: true

describe SubscriptionServer::UserResource do
  let!(:user) { Fabricate(:user) }
  let!(:subscription) {
    SubscriptionServer::Subscription.new(
      resource: 'discourse-events',
      product_id: "prod_CBTNpi3fqWWkq0",
      product_name: "Business Subscription",
      price_id: "1234567",
      price_name: "yearly"
    )
  }

  before do
    SiteSetting.subscription_server_iam_access_key = "12345"
    SiteSetting.subscription_server_iam_secret_access_key = "23l42l3nk423o2"
  end

  describe "#list" do
    it "returns the right user resources" do
      result = described_class.list(user.id, [subscription])
      expect(result[0]).to be_present
      expect(result[0].resource_name).to eq("discourse-events")
      expect(result[0].iam_user_name).to be_present
      expect(result[0].iam_access_key_id).to be_present
      expect(result[0].iam_secret_access_key).to be_present
      expect(result[0].iam_key_updated_at).to be_present
    end
  end
end
