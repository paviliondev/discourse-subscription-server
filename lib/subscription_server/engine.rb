module ::SubscriptionServer
  PLUGIN_NAME ||= 'subscription_server'

  class Engine < ::Rails::Engine
    isolate_namespace SubscriptionServer
    engine_name PLUGIN_NAME
  end
end