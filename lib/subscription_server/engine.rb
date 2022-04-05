# frozen_string_literal: true

module ::SubscriptionServer
  PLUGIN_NAME ||= 'subscription_server'

  class Engine < ::Rails::Engine
    isolate_namespace SubscriptionServer
    engine_name PLUGIN_NAME
  end

  # extensions namespace
  class Extensions; end
end
