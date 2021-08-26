# frozen_string_literal: true
require_relative '../../plugin_helper'

describe SubscriptionServer::UserSubscriptions do
  let(:user) { Fabricate(:user) }
  let(:provider) { "stripe" }
  let(:client_name) { "custom_wizard" }

  before do
    @instance = SubscriptionServer::UserSubscriptions.new(user)
  end

  def response_error(message)
    "Failed to load subscriptions for #{user.username}: #{message}"
  end

  context "load" do
    it "requires a valid provider" do
      invalid_provider = "braintree"
      @instance.load(provider: invalid_provider, client_name: client_name)
      expect(@instance.error).to eq(response_error("#{invalid_provider} is not a supported provider"))
    end

    it "requires the provider to be installed" do
      SubscriptionServer::Stripe.any_instance.stubs(:installed).returns(false)
      @instance.load(provider: provider, client_name: client_name)
      expect(@instance.error).to eq(response_error("#{provider} is not installed"))
    end

    context "with provider installed" do
      before do
        plugin = Plugin::Instance.new
        plugin.path = "#{Rails.root}/plugins/discourse-subscription-server/spec/fixtures/providers/stripe_plugin/plugin.rb"
        plugin.activate!
      end

      it "requires the provider to be setup" do
        @instance.load(provider: provider, client_name: client_name)
        expect(@instance.error).to eq(response_error("failed to setup #{provider}"))
      end

      context "with provider setup" do
        before do
          Stripe.api_key = "1234"
        end

        it "requires a valid client" do
          @instance.load(provider: provider, client_name: client_name)
          expect(@instance.error).to eq(response_error("no provider id found for #{client_name}"))
        end

        context "with a valid client" do
          before do
            SiteSetting.subscription_server_clients = "custom_wizard:#{Stripe::PRODUCT_ID}"
          end

          it "returns an error if no subscriptions" do
            Stripe::Customer.has_subscription = false
            @instance.load(provider: provider, client_name: client_name)
            expect(@instance.error).to eq(response_error("no subscriptions found"))
          end

          it "loads subscriptions" do
            Stripe::Customer.has_subscription = true
            @instance.load(provider: provider, client_name: client_name)
            expect(@instance.error).to eq(nil)
            expect(@instance.subscriptions.size).to eq(1)
          end
        end
      end
    end
  end
end
