Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "forecasts/new", to: "forecasts#new", as: :new_forecast
  get "forecasts/show", to: "forecasts#show", as: :forecast

  root "forecasts#new"
end
