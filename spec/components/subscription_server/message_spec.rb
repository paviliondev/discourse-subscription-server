# frozen_string_literal: true

describe SubscriptionServer::Message do
  it "#create" do
    message = described_class.create(title: "Info message")
    expect(message.class).to eq(described_class)
  end

  it "#create different types" do
    message = described_class.create(title: "Warning message", type: described_class.types[:warning])
    expect(message.type).to eq(described_class.types[:warning])
  end

  it "#find" do
    message = described_class.create(title: "Info message")
    expect(described_class.find(message.id).message).to eq(message.message)
  end

  it "#list" do
    described_class.create(title: "Info message")
    described_class.create(title: "Warning message", type: described_class.types[:warning])
    expect(described_class.list.length).to eq(2)
  end
end
