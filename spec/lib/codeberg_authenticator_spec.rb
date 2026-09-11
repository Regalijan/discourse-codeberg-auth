# frozen_string_literal: true

RSpec.describe "CodebergAuthenticator" do
  subject(:authenticator) do
    Discourse.authenticators.find { |auth| auth.name == "codeberg" }
  end

  before do
    SiteSetting.codeberg_client_id = "client_id"
    SiteSetting.codeberg_secret = "client_secret"
  end

  it "requires the login toggle" do
    expect(authenticator.enabled?).to eq(false)

    SiteSetting.enable_codeberg_login = true
    expect(authenticator.enabled?).to eq(true)
  end

  %i[codeberg_client_id codeberg_secret].each do |setting|
    it "disables login when #{setting} is unavailable" do
      SiteSetting.enable_codeberg_login = true
      SiteSetting.stubs(setting).returns("")

      expect(authenticator.enabled?).to eq(false)
    end

    it "rejects enabling login without #{setting}" do
      SiteSetting.public_send("#{setting}=", "")

      expect { SiteSetting.enable_codeberg_login = true }.to raise_error(
        Discourse::InvalidParameters
      )
    end

    it "preserves the existing guard against clearing #{setting} while enabled" do
      SiteSetting.enable_codeberg_login = true

      expect { SiteSetting.public_send("#{setting}=", "") }.to raise_error(
        Discourse::InvalidParameters
      )
    end
  end
end
