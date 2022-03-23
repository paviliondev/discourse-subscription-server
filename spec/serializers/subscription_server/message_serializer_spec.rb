# frozen_string_literal: true

describe SubscriptionServer::MessageSerializer do
  it 'should return message attributes' do
    message = SubscriptionServer::Message.create(message: "Info message")
    serialized = described_class.new(message)

    expect(serialized.message).to eq("Info message")
    expect(serialized.type).to eq("info")
  end
end
