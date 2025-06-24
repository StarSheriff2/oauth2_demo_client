Rails.application.routes.draw do
  # get "up" => "rails/health#show", as: :rails_health_check
  root "static#home"
  get "profile", to: "static#profile"

  # OAuth2 routes
  get "auth/login", to: "sessions#new", as: :new_session
  get "auth/callback", to: "sessions#callback", as: :auth_callback


  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
