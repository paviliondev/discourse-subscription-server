# frozen_string_literal: true

# name: discourse-subscription-server
# about: Use Discourse as a subscription server
# version: 0.1.0
# url: https://github.com/paviliondev/discourse-subscription-server
# authors: Angus McLeod

enabled_site_setting :subscription_server_enabled

after_initialize do
  %w[
    ../lib/subscription_server/engine.rb
    ../lib/subscription_server/subscription.rb
    ../lib/subscription_server/provider.rb
    ../lib/subscription_server/providers/stripe.rb
    ../lib/subscription_server/user_subscriptions.rb
    ../config/routes.rb
    ../app/controllers/subscription_server/user_subscriptions_controller.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end

  add_user_api_key_scope(:'user-subscription',
    methods: :get,
    actions: "subscription_server/user_subscriptions#index",
    params: :client_name
  )
end
