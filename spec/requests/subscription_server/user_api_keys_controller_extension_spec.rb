# frozen_string_literal: true

describe UserApiKeysController do
  fab!(:user) { Fabricate(:user) }

  let :public_key do
    <<~TXT
    -----BEGIN PUBLIC KEY-----
    MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDh7BS7Ey8hfbNhlNAW/47pqT7w
    IhBz3UyBYzin8JurEQ2pY9jWWlY8CH147KyIZf1fpcsi7ZNxGHeDhVsbtUKZxnFV
    p16Op3CHLJnnJKKBMNdXMy0yDfCAHZtqxeBOTcCo1Vt/bHpIgiK5kmaekyXIaD0n
    w0z/BYpOgZ8QwnI5ZwIDAQAB
    -----END PUBLIC KEY-----
    TXT
  end

  let :args do
    {
      scopes: 'read',
      client_id: "x" * 32,
      auth_redirect: 'http://over.the/rainbow',
      application_name: 'foo',
      public_key: public_key,
      nonce: SecureRandom.hex
    }
  end

  it "refuses to redirect to disallowed place" do
    sign_in(user)
    post "/user-api-key.json", params: args
    expect(response.status).to eq(403)
  end

  it "allows any redirect if the scope matches user subscriptions scope exactly" do
    SiteSetting.allow_user_api_key_scopes = SubscriptionServer::UserSubscriptions::SCOPE
    args[:scopes] = SubscriptionServer::UserSubscriptions::SCOPE
    sign_in(user)
    post "/user-api-key.json", params: args
    expect(response.status).to eq(302)
  end

  it "refuses to redirect to disallowed place if scopes include user subscriptions scope with other scopes" do
    SiteSetting.allow_user_api_key_scopes = "#{SubscriptionServer::UserSubscriptions::SCOPE}|read"
    args[:scopes] = "#{SubscriptionServer::UserSubscriptions::SCOPE},read"
    sign_in(user)
    post "/user-api-key.json", params: args
    expect(response.status).to eq(403)
  end
end
