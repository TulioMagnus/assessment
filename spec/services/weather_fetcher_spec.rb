# frozen_string_literal: true

require "rails_helper"

RSpec.describe WeatherFetcher do
  describe ".call" do
    it "returns cached weather data when cache entry exists" do
      data = { temperature: 20.0, temperature_unit: "°C" }
      allow(Rails.cache).to receive(:read).with("weather:forecast:US:postal:33101").and_return(data)
      allow(WeatherClient).to receive(:call)
      allow(Rails.cache).to receive(:write)

      result = described_class.call(cache_key: "forecast:US:postal:33101", latitude: "25.7617", longitude: "-80.1918")

      expect(result.success?).to be(true)
      expect(result.data).to eq({ weather: data, from_cache: true })
      expect(WeatherClient).not_to have_received(:call)
      expect(Rails.cache).not_to have_received(:write)
    end

    it "fetches and writes weather data when cache entry is missing" do
      data = { temperature: 20.0, temperature_unit: "°C" }
      allow(Rails.cache).to receive(:read).with("weather:forecast:US:postal:33101").and_return(nil)
      allow(WeatherClient).to receive(:call).and_return(
        BaseService::Result.new(data: data)
      )
      allow(Rails.cache).to receive(:write)

      result = described_class.call(cache_key: "forecast:US:postal:33101", latitude: "25.7617", longitude: "-80.1918")

      expect(result.success?).to be(true)
      expect(result.data).to eq({ weather: data, from_cache: false })
      expect(Rails.cache).to have_received(:write)
        .with("weather:forecast:US:postal:33101", data, expires_in: 30.minutes)
    end

    it "returns error when client fails" do
      allow(Rails.cache).to receive(:read).with("weather:forecast:US:postal:33101").and_return(nil)
      allow(WeatherClient).to receive(:call).and_return(
        BaseService::Result.new(error: "Weather service is temporarily unavailable.")
      )
      allow(Rails.cache).to receive(:write)

      result = described_class.call(cache_key: "forecast:US:postal:33101", latitude: "25.7617", longitude: "-80.1918")

      expect(result.success?).to be(false)
      expect(result.error).to eq("Weather service is temporarily unavailable.")
      expect(Rails.cache).not_to have_received(:write)
    end
  end
end
