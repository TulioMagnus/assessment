# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Forecasts", type: :request do
  let(:resolver) { instance_double(LocationResolver) }

  before do
    allow(LocationResolver).to receive(:new).and_return(resolver)
  end

  describe "GET /forecasts/new" do
    it "renders country, postal code, and address inputs" do
      get new_forecast_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('name="country"')
      expect(response.body).to include('name="postal_code"')
      expect(response.body).to include('name="address"')
    end
  end

  describe "GET /forecasts/show" do
    it "validates missing country" do
      get forecast_path, params: { postal_code: "33101", address: "" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Country is required.")
    end

    it "validates that postal code or address is present" do
      get forecast_path, params: { country: "US", postal_code: "", address: "" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Provide postal code or address.")
    end

    it "validates unsupported country iso code" do
      get forecast_path, params: { country: "ZZ", postal_code: "12345", address: "" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Country must be a supported ISO code.")
    end

    it "resolves using postal code first when both are provided" do
      allow(resolver).to receive(:resolve).and_return(
        LocationResolver::Resolution.new(
          lat: "25.7617",
          lon: "-80.1918",
          postal_code: "33101",
          source: :postal_code
        )
      )

      get forecast_path, params: { country: "us", postal_code: "33101", address: "Miami, FL" }

      expect(response).to have_http_status(:ok)
      expect(resolver).to have_received(:resolve).with(country: "US", postal_code: "33101", address: "Miami, FL")
      expect(response.body).to include("Country: US")
      expect(response.body).to include("Postal/ZIP: 33101")
      expect(response.body).to include("Resolved by: Postal code")
      expect(response.body).to include("forecast:US:postal:33101")
    end

    it "falls back to address if postal geocoding fails and address is present" do
      allow(resolver).to receive(:resolve).and_return(
        LocationResolver::Resolution.new(
          lat: "51.5034",
          lon: "-0.1276",
          postal_code: nil,
          source: :address
        )
      )

      get forecast_path, params: { country: "GB", postal_code: "BADZIP", address: "10 Downing St, London" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Resolved by: Address")
      expect(response.body).to include("forecast:GB:grid:51.5:-0.13")
    end

    it "shows postal-not-found error when postal is provided and no address fallback exists" do
      allow(resolver).to receive(:resolve).and_return(
        LocationResolver::Resolution.new(error: "Postal code not found for selected country.")
      )

      get forecast_path, params: { country: "BR", postal_code: "00000", address: "" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Postal code not found for selected country.")
    end
  end
end
