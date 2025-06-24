class StaticController < ApplicationController
  def home
  end

  def profile
    # Retrieve the access token from the session
    access_token = session[:access_token]

    if access_token.nil?
      # Redirect to OAuth2 flow if user is not authenticated
      redirect_to new_session_path and return
    end

    # Use the access token to fetch user data
    token = OAuth2::AccessToken.new(Oauth2Client.client, access_token)

    begin
      # Fetch user details from the API (adjust the endpoint as needed)
      response = token.get('/api/v1/me')
      @user = JSON.parse(response.body)
    rescue => e
      @error_message = "Error fetching user data: #{e.message}"
    end
  end
end
