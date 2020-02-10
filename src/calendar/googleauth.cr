require "oauth2"

class OAuth2::Session
  def check_refresh_token
    previous_def
  end
end

module Google::Auth
  class TokenStore
    def initialize(client_id, client_secret, access_token, expires_at, refresh_token, scope)
      expires_at = Time.unix(expires_at.to_i)
      client = OAuth2::Client.new("https://accounts.google.com", client_id, client_secret, authorize_uri: "https://accounts.google.com/o/oauth2/auth", token_uri: "https://accounts.google.com/o/oauth2/token")
      access_token = OAuth2::AccessToken::Bearer.from_json({
        "access_token"  => access_token,
        "expires_in"    => (expires_at - Time.utc).to_i,
        "refresh_token" => refresh_token,
        "scope"         => scope,
      }.to_json)
      @session = OAuth2::Session.new(client, access_token, expires_at) { }
    end

    def token
      @session.check_refresh_token
      @session.access_token.access_token
    end
  end
end
