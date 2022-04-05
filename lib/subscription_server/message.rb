# frozen_string_literal: true

class SubscriptionServer::Message
  include ActiveModel::Serialization

  attr_reader :id,
              :title,
              :message,
              :type,
              :resource,
              :created_at,
              :expired_at

  def initialize(id, attrs)
    @id = id
    @title = attrs[:title]
    @message = attrs[:message]
    @resource = attrs[:resource]
    @type = attrs[:type]
    @created_at = attrs[:created_at]
    @expired_at = attrs[:expired_at]
  end

  def expire
    PluginStore.set(
      self.class.namespace,
      id,
      title: title,
      message: message,
      type: type,
      created_at: created_at,
      expired_at: Time.now
    )
  end

  def destroy
    PluginStore.remove(self.class.namespace, id)
  end

  def self.types
    @types ||= Enum.new(
      info: 0,
      warning: 1
    )
  end

  def self.namespace
    "#{SubscriptionServer::PLUGIN_NAME}_message"
  end

  def self.find(id)
    if raw = PluginStore.get(namespace, id)
      new(id, raw.symbolize_keys)
    else
      false
    end
  end

  def self.create(title: '', message: nil, type: 0, resource: nil)
    created_at = Time.now.iso8601(3)
    id = Digest::SHA1.hexdigest(title + created_at.to_s)
    return false if find(id) || types.key(type).blank?

    if PluginStore.set(
      namespace,
      id,
      title: title,
      message: message,
      type: type,
      resource: resource,
      created_at: created_at
    )
      find(id)
    else
      false
    end
  end

  def self.list_query(attr = nil, value = nil)
    query = PluginStoreRow.where(plugin_name: namespace)
    query = query.where("(value::json->>'#{attr}') = ?", value) if attr && value
    query.order("value::json->>'created_at' DESC")
  end

  def self.list(attr = nil, value = nil)
    list_query(attr, value)
      .map { |r| new(r.key, JSON.parse(r.value).symbolize_keys) }
  end
end
