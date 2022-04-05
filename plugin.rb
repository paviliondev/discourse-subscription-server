# frozen_string_literal: true

# name: discourse-subscription-server
# about: Use Discourse as a subscription server
# version: 0.2.0
# url: https://github.com/paviliondev/discourse-subscription-server
# authors: Angus McLeod

enabled_site_setting :subscription_server_enabled

after_initialize do
  %w[
    ../lib/subscription_server/engine.rb
    ../lib/subscription_server/subscription.rb
    ../lib/subscription_server/provider.rb
    ../lib/subscription_server/message.rb
    ../lib/subscription_server/providers/stripe.rb
    ../lib/subscription_server/user_subscriptions.rb
    ../lib/subscription_server/extensions/user_api_key.rb
    ../lib/subscription_server/extensions/user_api_keys_controller.rb
    ../config/routes.rb
    ../app/controllers/subscription_server/user_subscriptions_controller.rb
    ../app/controllers/subscription_server/messages_controller.rb
    ../app/controllers/subscription_server/server_controller.rb
    ../app/serializers/subscription_server/message_serializer.rb
    ../app/serializers/subscription_server/subscription_serializer.rb
  ].each do |path|
    load File.expand_path(path, __FILE__)
  end

  UserApiKey.singleton_class.prepend SubscriptionServer::Extensions::UserApiKey
  UserApiKeysController.prepend SubscriptionServer::Extensions::UserApiKeysController

  add_user_api_key_scope(:user_subscription,
    methods: :get,
    actions: "subscription_server/user_subscriptions#index",
    params: :client_name
  )
end
