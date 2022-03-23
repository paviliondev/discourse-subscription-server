# frozen_string_literal: true

describe SubscriptionServer::UserSubscriptions do
  let(:user) { Fabricate(:user) }
  let(:provider) { "stripe" }
  let(:invalid_provider) { "braintree" }
  let(:provider_id) { "prod_CBTNpi3fqWWkq0" }
  let(:resource) { "custom_wizard" }
  let(:subscriptions) { "#{resource}:#{provider}:#{provider_id}" }
  let(:resources) { [resource] }

  before do
    @instance = SubscriptionServer::UserSubscriptions.new(user)
  end

  def response_error(message)
    "Failed to load #{resource} subscriptions for #{user.username}: #{message}"
  end

  it "requires subscriptions" do
    @instance.load(resources)
    expect(@instance.errors).to include(response_error("no subscription found for #{resource}"))
  end

  context "with subscriptions" do
    before do
      SiteSetting.subscription_server_subscriptions = subscriptions
    end

    it "requires the provider to be installed" do
      SubscriptionServer::Stripe.any_instance.stubs(:installed?).returns(false)
      @instance.load(resources)
      expect(@instance.errors).to include(response_error("#{provider} is not installed"))
    end

    context "with provider installed" do
      before do
        plugin = Plugin::Instance.new
        plugin.path = "#{Rails.root}/plugins/discourse-subscription-server/spec/fixtures/providers/stripe_plugin/plugin.rb"
        plugin.activate!
      end

      it "requires the provider to be setup" do
        @instance.load(resources)
        expect(@instance.errors).to include(response_error("failed to setup #{provider}"))
      end

      context "with provider setup" do
        before do
          Stripe.api_key = "1234"
        end

        it "returns an error if no subscriptions" do
          Stripe::Customer.has_subscription = false
          @instance.load(resources)
          expect(@instance.errors).to include(response_error("no subscriptions found for #{resource}"))
        end

        it "loads subscriptions" do
          Stripe::Customer.has_subscription = true
          @instance.load(resources)
          expect(@instance.errors).to eq([])
          expect(@instance.subscriptions.size).to eq(1)
          expect(@instance.subscriptions.first.product_id).to eq(Stripe::PRODUCT_ID)
        end
      end
    end
  end
end
