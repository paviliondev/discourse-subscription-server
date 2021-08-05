SubscriptionServer::Engine.routes.draw do
  get '/user-subscriptions/:client_name' => 'user_subscriptions#index'
end

Discourse::Application.routes.append do
  mount ::SubscriptionServer::Engine, at: "/subscription-server"
end