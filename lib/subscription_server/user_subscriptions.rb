SubscriptionInfo = Struct.new(:product_id, :price_id, :price_nickname, keyword_init: true)

class SubscriptionServer::UserSubscriptions
  include SubscriptionServer::Stripe

  attr_reader :user
  attr_accessor :subscriptions

  def initialize(user)
    @user = user
    @subscriptions = []
  end

  def load(opts)
    @type = opts[:subscription_type]
    @client = opts[:client_name]

    load_method = "#{@type}_load"
    installed_method = "#{@type}_installed"
    initialize_method = "#{@type}_initialize"

    return false unless self.respond_to?(load_method) &&
      self.respond_to?(installed_method) &&
      self.send(installed_method) &&
      self.send(initialize_method)

    product_id = client_products[@client.to_sym]
    unless product_id
      Rails.logger.warn("Subscription Server Log: no client found for user #{@user.username} with #{opts.to_s}")
      return false
    end

    self.send(load_method, product_id)
  end

  def any?
    @subscriptions.any?
  end

  def info
    @subscriptions.map do |subscription|
      self.send("#{@type}_subscription_info", subscription).to_h
    end
  end

  protected

  def client_products
    @client_products ||= SiteSetting.subscription_server_client_products.split('|')
      .reduce({}) do |result, item|
        parts = item.split(':')
        result[parts.first.to_sym] = parts.second
        result
      end
  end
end