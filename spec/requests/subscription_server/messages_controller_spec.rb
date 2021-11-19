# frozen_string_literal: true
require_relative '../../plugin_helper'

describe SubscriptionServer::MessagesController do
  it "returns messages" do
    SubscriptionServer::Message.create(message: "Info message body", title: "Info message title")
    SubscriptionServer::Message.create(message: "Warning message body", title: "Warning message title", type: SubscriptionServer::Message.types[:warning])

    get "/subscription-server/messages.json"
    expect(response.status).to eq(200)

    messages = response.parsed_body['messages']
    expect(messages.length).to eq(2)
    expect(messages.first['type']).to eq("warning")
    expect(messages.first['message']).to eq("Warning message body")
    expect(messages.second['type']).to eq("info")
    expect(messages.second['message']).to eq("Info message body")
  end
end
