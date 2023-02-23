# frozen_string_literal: true

describe SubscriptionServer::ServerController do
  let(:provider) { "stripe" }
  let(:product_id) { "prod_CBTNpi3fqWWkq0" }
  let(:product_slug) { "business" }
  let(:resource) { "custom_wizard" }

  it "returns a 404 if the server details are not set" do
    get "/subscription-server"
    expect(response.status).to eq(404)
  end

  it "returns server details" do
    SiteSetting.subscription_server_supplier_name = "Pavilion"
    SiteSetting.subscription_server_subscriptions = "#{resource}:#{product_slug}:#{provider}:#{product_id}"
    get "/subscription-server"
    expect(response.status).to eq(200)
    expect(response.parsed_body["supplier"]).to eq("Pavilion")
    expect(response.parsed_body["products"]).to eq(
      {
        "#{resource}": [
          {
            product_slug: product_slug,
            product_id: product_id
          }
        ]
      }.as_json
    )
  end
end
