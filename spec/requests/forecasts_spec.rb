# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Forecasts", type: :request do
  describe "GET /forecasts/new" do
    it "renders the search form with address input only" do
      get new_forecast_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="address"')
    end
  end

  describe "GET /forecasts/show" do
    it "renders results when address is provided" do
      get forecast_path, params: { address: "123 Main St, Miami, FL" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Address: 123 Main St, Miami, FL")
    end

    it "returns validation error when address is blank" do
      get forecast_path, params: { address: "   " }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Please enter an address.")
    end
  end
end
