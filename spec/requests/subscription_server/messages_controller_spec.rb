# frozen_string_literal: true

describe SubscriptionServer::MessagesController do
  it "returns messages" do
    SubscriptionServer::Message.create(message: "Info message body", title: "Info message title")
    SubscriptionServer::Message.create(message: "Warning message body", title: "Warning message title", type: SubscriptionServer::Message.types[:warning])
    SubscriptionServer::Message.create(message: "Resource warning message body", title: "Resource warning message title", type: SubscriptionServer::Message.types[:warning], resource: "custom-wizard-plugin")

    get "/subscription-server/messages.json"
    expect(response.status).to eq(200)

    messages = response.parsed_body['messages']
    expect(messages.length).to eq(3)
    expect(messages.first['type']).to eq("warning")
    expect(messages.first['message']).to eq("Resource warning message body")
    expect(messages.first['resource']).to eq("custom-wizard-plugin")
    expect(messages.second['type']).to eq("warning")
    expect(messages.second['message']).to eq("Warning message body")
    expect(messages.last['type']).to eq("info")
    expect(messages.last['message']).to eq("Info message body")
  end
end
