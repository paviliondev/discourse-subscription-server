# frozen_string_literal: true
require_relative '../../plugin_helper'

describe SubscriptionServer::Message do
  it "#create" do
    message = described_class.create(message: "Info message")
    expect(message.class).to eq(described_class)
  end

  it "#create different types" do
    message = described_class.create(message: "Info message", type: described_class.types[:error])
    expect(message.type).to eq(described_class.types[:error])
  end

  it "#find" do
    message = described_class.create(message: "Info message")
    expect(described_class.find(message.id).message).to eq(message.message)
  end

  it "#list" do
    described_class.create(message: "Info message")
    described_class.create(message: "Warning message", type: described_class.types[:warning])
    described_class.create(message: "Error message", type: described_class.types[:error])
    expect(described_class.list.length).to eq(3)
  end
end