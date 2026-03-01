# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Forecasts", type: :request do
  let(:weather_data) do
    {
      observed_at: "2026-03-01T09:00",
      temperature: 27.1,
      temperature_unit: "°C",
      feels_like: 29.0,
      feels_like_unit: "°C",
      precipitation: 0.0,
      precipitation_unit: "mm",
      wind_speed: 10.2,
      wind_speed_unit: "km/h",
      weather_code: 1
    }
  end
  let(:lookup_data) do
    {
      resolved_lat: "25.7617",
      resolved_lon: "-80.1918",
      resolved_postal_code: "33101",
      resolution_source: :postal_code,
      cache_key: "forecast:US:postal:33101",
      weather: weather_data,
      weather_from_cache: false,
      weather_error: nil
    }
  end

  before do
    allow(ForecastLookup).to receive(:call).and_return(
      BaseService::Result.new(data: lookup_data)
    )
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
      expect(ForecastLookup).not_to have_received(:call)
    end

    it "validates that postal code or address is present" do
      get forecast_path, params: { country: "US", postal_code: "", address: "" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Provide postal code or address.")
      expect(ForecastLookup).not_to have_received(:call)
    end

    it "validates unsupported country iso code" do
      get forecast_path, params: { country: "ZZ", postal_code: "12345", address: "" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Country must be a supported ISO code.")
      expect(ForecastLookup).not_to have_received(:call)
    end

    it "resolves using postal code first when both are provided" do
      captured_input = nil
      allow(ForecastLookup).to receive(:call) do |input:|
        captured_input = input
        BaseService::Result.new(data: lookup_data)
      end

      get forecast_path, params: { country: "us", postal_code: "33101", address: "Miami, FL" }

      expect(response).to have_http_status(:ok)
      expect(captured_input).to be_a(ForecastInput)
      expect(captured_input.country).to eq("US")
      expect(captured_input.postal_code).to eq("33101")
      expect(captured_input.address).to eq("Miami, FL")
      expect(response.body).to include("Country: US")
      expect(response.body).to include("Postal/ZIP: 33101")
      expect(response.body).to include("Resolved by: Postal code")
      expect(response.body).to include("Weather source: Live fetch")
      expect(response.body).to include("forecast:US:postal:33101")
      expect(response.body).to include("Temperature: 27.1 °C")
    end

    it "falls back to address if postal geocoding fails and address is present" do
      allow(ForecastLookup).to receive(:call).and_return(
        BaseService::Result.new(
          data: lookup_data.merge(
            resolved_lat: "51.5034",
            resolved_lon: "-0.1276",
            resolved_postal_code: nil,
            resolution_source: :address,
            cache_key: "forecast:GB:grid:51.5:-0.13"
          )
        )
      )

      get forecast_path, params: { country: "GB", postal_code: "BADZIP", address: "10 Downing St, London" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Resolved by: Address")
      expect(response.body).to include("Weather source: Live fetch")
      expect(response.body).to include("forecast:GB:grid:51.5:-0.13")
    end

    it "shows cache indicator when weather comes from cache" do
      allow(ForecastLookup).to receive(:call).and_return(
        BaseService::Result.new(data: lookup_data.merge(weather_from_cache: true))
      )

      get forecast_path, params: { country: "US", postal_code: "33101", address: "" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Weather source: Cache")
    end

    it "shows weather error when weather service fails" do
      allow(ForecastLookup).to receive(:call).and_return(
        BaseService::Result.new(
          data: lookup_data.merge(
            resolved_lat: "40.7128",
            resolved_lon: "-74.0060",
            resolved_postal_code: "10007",
            cache_key: "forecast:US:postal:10007",
            weather: nil,
            weather_from_cache: nil,
            weather_error: "Weather service is temporarily unavailable."
          )
        )
      )

      get forecast_path, params: { country: "US", postal_code: "10007", address: "" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Weather service is temporarily unavailable.")
    end

    it "shows postal-not-found error when postal is provided and no address fallback exists" do
      allow(ForecastLookup).to receive(:call).and_return(
        BaseService::Result.new(error: "Postal code not found for selected country.")
      )

      get forecast_path, params: { country: "BR", postal_code: "00000", address: "" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Postal code not found for selected country.")
    end
  end
end
