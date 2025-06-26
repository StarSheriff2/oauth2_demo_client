class StaticController < ApplicationController
  before_action :set_client, only: :profile
  def home
  end

  def profile
    # Retrieve the access token from the session
    access_token = session[:token]

    if access_token.nil?
      # Redirect to OAuth2 flow if user is not authenticated
      redirect_to new_session_path and return
    end

    # Use the access token to fetch user data
    token = OAuth2::AccessToken.from_hash(@client, access_token)

    if token.expired?
      # Attempt to refresh the token
      token = token.refresh!
      return unless token
      session[:access_token] = token
    end

    begin
      # Fetch user details from the API (adjust the endpoint as needed)
      response = token.get("/api/v1/me")
      @user = JSON.parse(response.body)
    rescue => e
      @error_message = "Error fetching user data: #{e.message}"
    end
  end

  private

  def set_client
    @client ||= OAuth2::Client.new(
      ENV.fetch("OAUTH_CLIENT_ID", "wDgTBDxqXpO0gqLXtVW2zEanhOTEopYKPvJJkQUvSMw"),
      ENV.fetch("OAUTH_CLIENT_SECRET", "1D-kA4jDMYKvD4q1Elw7uUEkHN4PsXPmreLKBQR2fd4"),
      site: ENV.fetch("OAUTH_SITE_URL", "http://localhost:3000"),
      authorize_url: "api/v1/oauth2/authorize", revoke_url: "api/v1/oauth2/revoke",
      token_url: "api/v1/oauth2/token"
    )
  end
end
