# frozen_string_literal: true

SubscriptionServer::Engine.routes.draw do
  get '/user-subscriptions/:provider/:client_name' => 'user_subscriptions#index'
  get '/messages' => 'messages#index'
end

Discourse::Application.routes.append do
  mount ::SubscriptionServer::Engine, at: "/subscription-server"
end
