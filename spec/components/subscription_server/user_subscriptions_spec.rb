# frozen_string_literal: true

describe SubscriptionServer::UserSubscriptions do
  let(:user) { Fabricate(:user) }
  let(:provider) { "stripe" }
  let(:invalid_provider) { "braintree" }
  let(:product_id) { "prod_CBTNpi3fqWWkq0" }
  let(:product_slug) { "business" }
  let(:resource) { "custom_wizard" }
  let(:subscriptions) { "#{resource}:#{product_slug}:#{provider}:#{product_id}" }
  let(:resources) { [resource] }
  let(:domain) { "demo.pavilion.tech" }

  before do
    @instance = SubscriptionServer::UserSubscriptions.new(user, domain)
  end

  def response_error(message)
    "Failed to load #{resource} subscriptions for #{user.username}: #{message}"
  end

  it "requires resources" do
    expect(@instance.load).to eq(nil)
  end

  it "requires a domain" do
    instance = SubscriptionServer::UserSubscriptions.new(user)
    expect(instance.load(resources)).to eq(nil)
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
        SubscriptionServer::Stripe.any_instance.stubs(:discourse_subscriptions_installed?).returns(false)
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

          subscription = @instance.subscriptions.first
          expect(subscription.product_id).to eq(Stripe::PRODUCT_ID)
          expect(subscription.product_name).to eq(Stripe::PRODUCT_NAME)
          expect(subscription.price_id).to eq(Stripe::PRICE_ID)
          expect(subscription.price_name).to eq(Stripe::PRICE_NAME)
        end

        context "with domain limit" do
          before do
            Stripe::Customer.has_subscription = true
            SiteSetting.subscription_server_subscriptions = subscriptions + ":1"
          end

          it "returns an error if the domain limit is exceeded" do
            @instance.load(resources)
            instance = SubscriptionServer::UserSubscriptions.new(user, "second.pavilion.tech")
            instance.load(resources)
            expect(instance.errors).to include(response_error("domain limit reached for #{resource}"))
          end

          it "doesn't return an error if the domain is the same as an existing domain registered by the user" do
            @instance.load(resources)
            instance = SubscriptionServer::UserSubscriptions.new(user, domain)
            instance.load(resources)
            expect(instance.errors).to eq([])
            expect(instance.subscriptions.size).to eq(1)
          end

          it "loads subscriptions if the domain limit is not exceeded" do
            SiteSetting.subscription_server_subscriptions = subscriptions + ":2"

            @instance.load(resources)
            instance = SubscriptionServer::UserSubscriptions.new(user, "second.pavilion.tech")
            instance.load(resources)
            expect(instance.errors).to eq([])
            expect(instance.subscriptions.size).to eq(1)
          end
        end
      end
    end
  end
end
