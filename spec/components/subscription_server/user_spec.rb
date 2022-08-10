# frozen_string_literal: true

describe User do
  fab!(:user) { Fabricate(:user) }
  let(:provider) { "stripe" }
  let(:product_id) { "prod_CBTNpi3fqWWkq0" }
  let(:resource) { "custom_wizard" }
  let(:domain) { "demo.pavilion.tech" }
  let(:another_domain) { "another.pavilion.tech" }
  let(:domain_limit) { 1 }
  let(:subscriptions) { "#{resource}:#{provider}:#{product_id}:#{domain_limit.to_s}" }

  before do
    SiteSetting.subscription_server_subscriptions = subscriptions
  end

  it "#add_subscription_product_domain" do
    user.add_subscription_product_domain(domain, resource, provider, product_id)
    expect(user.custom_fields[user.subscription_product_domain_key(resource, provider, product_id)]).to eq(domain)
  end

  it "#subscription_product_domains" do
    user.add_subscription_product_domain(domain, resource, provider, product_id)
    user.add_subscription_product_domain(another_domain, resource, provider, product_id)
    expect(user.subscription_product_domains(resource, provider, product_id)).to eq([domain, another_domain])
  end

  it "#subscription_domains" do
    user.add_subscription_product_domain(domain, resource, provider, product_id)
    expect(user.subscription_domains.size).to eq(1)
    expect(user.subscription_domains.first[:resource]).to eq(resource)
    expect(user.subscription_domains.first[:products]).to eq([product_id])
    expect(user.subscription_domains.first[:domains]).to eq([domain])
    expect(user.subscription_domains.first[:domain_limit]).to eq(1)
  end
end
