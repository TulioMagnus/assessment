# frozen_string_literal: true

require "rails_helper"

RSpec.describe ForecastLookup do
  let(:input) { ForecastInput.new(country: "US", postal_code: "33101", address: "Miami, FL") }
  let(:resolver) { instance_double(LocationResolver) }

  before do
    allow(LocationResolver).to receive(:new).and_return(resolver)
  end

  describe ".call" do
    it "returns assembled forecast data when resolution succeeds" do
      allow(resolver).to receive(:resolve).and_return(
        LocationResolver::Resolution.new(
          lat: "25.7617",
          lon: "-80.1918",
          postal_code: "33101",
          source: :postal_code
        )
      )
      allow(ForecastCacheKeyBuilder).to receive(:call).and_return("forecast:US:postal:33101")
      allow(WeatherFetcher).to receive(:call).and_return(
        BaseService::Result.new(
          data: {
            weather: { temperature: 27.1, temperature_unit: "°C" },
            from_cache: false
          }
        )
      )

      result = described_class.call(input: input)

      expect(result.success?).to be(true)
      expect(result.data[:country]).to eq("US")
      expect(result.data[:resolved_postal_code]).to eq("33101")
      expect(result.data[:cache_key]).to eq("forecast:US:postal:33101")
      expect(result.data[:weather][:temperature]).to eq(27.1)
      expect(result.data[:weather_from_cache]).to be(false)
      expect(result.data[:weather_error]).to be_nil
    end

    it "returns failure when location resolution fails" do
      allow(resolver).to receive(:resolve).and_return(
        LocationResolver::Resolution.new(error: "Postal code not found for selected country.")
      )

      result = described_class.call(input: input)

      expect(result.success?).to be(false)
      expect(result.error).to eq("Postal code not found for selected country.")
    end

    it "falls back to normalized input postal code when source is postal_code without resolved postal code" do
      input = ForecastInput.new(country: "CA", postal_code: "h2y 1c6", address: "")
      allow(resolver).to receive(:resolve).and_return(
        LocationResolver::Resolution.new(
          lat: "45.503",
          lon: "-73.57",
          postal_code: nil,
          source: :postal_code
        )
      )
      allow(ForecastCacheKeyBuilder).to receive(:call).and_return("forecast:CA:postal:H2Y1C6")
      allow(WeatherFetcher).to receive(:call).and_return(
        BaseService::Result.new(data: { weather: {}, from_cache: true })
      )

      result = described_class.call(input: input)

      expect(result.success?).to be(true)
      expect(result.data[:resolved_postal_code]).to eq("H2Y 1C6")
    end
  end
end
