# frozen_string_literal: true
require_relative '../../plugin_helper'

describe SubscriptionServer::MessagesController do
  it "returns messages" do
    SubscriptionServer::Message.create(message: "Info message")
    SubscriptionServer::Message.create(message: "Error message", type: SubscriptionServer::Message.types[:error])

    get "/subscription-server/messages.json"
    expect(response.status).to eq(200)

    messages = response.parsed_body['messages']
    expect(messages.length).to eq(2)
    expect(messages.first['type']).to eq("error")
    expect(messages.first['message']).to eq("Error message")
    expect(messages.second['type']).to eq("info")
    expect(messages.second['message']).to eq("Info message")
  end
end
