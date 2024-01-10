# frozen_string_literal: true

SubscriptionServer::Engine.routes.draw do
  get '' => 'server#index', defaults: { format: 'json' }
  get 'user-subscriptions' => 'user_subscriptions#index', defaults: { format: 'json' }
  get 'messages' => 'messages#index', defaults: { format: 'json' }
  delete 'user-authorizations' => 'user_authorizations#destroy', defaults: { format: 'json' }
end

Discourse::Application.routes.append do
  mount ::SubscriptionServer::Engine, at: "/subscription-server"
  get '/subscribe' => 'discourse_subscriptions/subscribe#index'
end
