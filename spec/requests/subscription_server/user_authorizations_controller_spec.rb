# frozen_string_literal: true

describe SubscriptionServer::UserAuthorizationsController do
  let(:user) { Fabricate(:user) }
  let(:provider) { "stripe" }
  let(:product_id) { "prod_CBTNpi3fqWWkq0" }
  let(:product_slug) { "business" }
  let(:resource) { "custom_wizard" }
  let(:domain) { "demo.pavilion.tech" }

  it "requires a user" do
    delete "/subscription-server/user-authorizations"
    expect(response.status).to eq(403)
  end

  context "with a user" do
    before do
      sign_in(user)
    end

    describe "#destroy" do

      it "requires a domain" do
        delete "/subscription-server/user-authorizations"
        expect(response.status).to eq(400)
      end

      it "removes the domain from all of the user's products" do
        user.add_subscription_product_domain(domain, resource, provider, product_id)
        user.add_subscription_product_domain(domain, resource, provider, "prod_12345")

        delete "/subscription-server/user-authorizations", params: { domain: domain }
        expect(response.status).to eq(200)

        user.reload
        expect(user.custom_fields[user.subscription_product_domain_key(resource, provider, product_id)]).to eq("")
        expect(user.custom_fields[user.subscription_product_domain_key(resource, provider, "prod_12345")]).to eq("")
      end
    end
  end
end
