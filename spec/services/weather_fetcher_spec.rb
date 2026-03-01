# frozen_string_literal: true

require "rails_helper"

RSpec.describe WeatherFetcher do
  let(:weather_client) { instance_double(WeatherClient) }

  describe ".call" do
    it "returns weather data when client succeeds" do
      data = { temperature: 20.0, temperature_unit: "°C" }
      allow(WeatherClient).to receive(:new).and_return(weather_client)
      allow(weather_client).to receive(:current_weather).and_return(
        WeatherClient::Result.new(data: data)
      )

      expect(Rails.cache).to receive(:fetch)
        .with("weather:forecast:US:postal:33101", expires_in: 30.minutes)
        .and_yield

      result = described_class.call(cache_key: "forecast:US:postal:33101", latitude: "25.7617", longitude: "-80.1918")

      expect(result.success?).to be(true)
      expect(result.data).to eq(data)
    end

    it "returns error when client fails" do
      allow(WeatherClient).to receive(:new).and_return(weather_client)
      allow(weather_client).to receive(:current_weather).and_return(
        WeatherClient::Result.new(error: "Weather service is temporarily unavailable.")
      )
      allow(Rails.cache).to receive(:fetch).and_yield

      result = described_class.call(cache_key: "forecast:US:postal:33101", latitude: "25.7617", longitude: "-80.1918")

      expect(result.success?).to be(false)
      expect(result.error).to eq("Weather service is temporarily unavailable.")
    end
  end
end
