# frozen_string_literal: true

describe SubscriptionServer::ServerController do
  it "returns a 404 if the server details are not set" do
    get "/subscription-server"
    expect(response.status).to eq(404)
  end

  it "returns server details" do
    SiteSetting.subscription_server_supplier_name = "Pavilion"
    get "/subscription-server"
    expect(response.status).to eq(200)
    expect(response.parsed_body["supplier"]).to eq("Pavilion")
  end
end
