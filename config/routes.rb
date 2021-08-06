SubscriptionServer::Engine.routes.draw do
  get '/user-subscriptions/:subscription_type/:client_name' => 'user_subscriptions#index'
end

Discourse::Application.routes.append do
  mount ::SubscriptionServer::Engine, at: "/subscription-server"
end