class SessionsController < ApplicationController
  before_action :set_client
  def new
    max_retries = 5
    attempts = 0

    begin
      # Attempt to check the provider and redirect
      verify_oauth_provider_up!
      authorization_url = @client.auth_code.authorize_url(
        response_type: "code",
        scope: "read",
        redirect_uri: "http://localhost:3001/auth/callback",
        connection_opts: {
          request: {
            timeout: 10,
            open_timeout: 5
          }
        }
      )

      redirect_to authorization_url
    rescue OAuth2::Error, SocketError, Errno::ECONNREFUSED, Timeout::Error => e
      attempts += 1
      Rails.logger.warn("Attempt #{attempts} - Unable to connect to OAuth provider: #{e.message}")

      if attempts < max_retries
        Rails.logger.info("Retrying attempt #{attempts + 1}...")
        sleep 2 # Small delay before retrying
        retry
      else
        Rails.logger.error("Max retries reached. OAuth provider is down: #{e.message}")
        flash[:alert] = "We are unable to connect to the authentication provider at the moment. Please try again later."
        redirect_to root_path
      end
    end
  end

  def callback
    # Retrieve the code from the callback params
    auth_code = params[:code]

    # Exchange the code for an access token
    token = @client.auth_code.get_token(
      auth_code,
      redirect_uri: "http://localhost:3001/auth/callback"
    )

    # Store the token securely (e.g., in session)
    session[:access_token] = token.token

    # Redirect to profile page
    redirect_to profile_path
  end

  private

  def set_client
    @client ||= OAuth2::Client.new(
      ENV.fetch("OAUTH_CLIENT_ID", "wDgTBDxqXpO0gqLXtVW2zEanhOTEopYKPvJJkQUvSMw"),
      ENV.fetch("OAUTH_CLIENT_SECRET", "1D-kA4jDMYKvD4q1Elw7uUEkHN4PsXPmreLKBQR2fd4"),
      site: ENV.fetch("OAUTH_SITE_URL", "http://localhost:3000"),
      authorize_url: "api/v1/oauth2/authorize", :revoke_url=>"api/v1/oauth2/revoke",
      token_url: "api/v1/oauth2/token"
    )
  end

  def verify_oauth_provider_up!
    uri = URI.parse(ENV.fetch("OAUTH_SITE_URL", "http://localhost:3000"))
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new(uri)
      response = http.request(request)

      unless response.is_a?(Net::HTTPSuccess)
        raise "OAuth provider is not responding with a success status (#{response.code})"
      end
    end
  end
end
