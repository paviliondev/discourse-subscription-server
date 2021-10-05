# frozen_string_literal: true

class SubscriptionServer::MessagesController < ApplicationController
  skip_before_action :check_xhr, :preload_json, :verify_authenticity_token

  def index
    render_serialized(SubscriptionServer::Message.list, SubscriptionServer::MessageSerializer, root: 'messages')
  end
end