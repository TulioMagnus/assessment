# frozen_string_literal: true

require "rails_helper"

RSpec.describe LocationResolver do
  describe "#resolve" do
    it "tries postal code first when both postal code and address are provided" do
      resolver = described_class.new
      postal_resolution = described_class::Resolution.new(lat: "25.7617", lon: "-80.1918", source: :postal_code)

      expect(resolver).to receive(:geocode)
        .with(query: "33101, US", country_code: "us", source: :postal_code)
        .and_return(postal_resolution)
      expect(resolver).not_to receive(:geocode)
        .with(query: "Miami, FL, US", country_code: "us", source: :address)

      result = resolver.resolve(country: "US", postal_code: "33101", address: "Miami, FL")

      expect(result.success?).to be(true)
      expect(result.source).to eq(:postal_code)
    end

    it "falls back to address when postal code geocoding fails" do
      resolver = described_class.new
      address_resolution = described_class::Resolution.new(lat: "51.5034", lon: "-0.1276", source: :address)

      expect(resolver).to receive(:geocode)
        .with(query: "SW1A, GB", country_code: "gb", source: :postal_code)
        .and_return(nil)
      expect(resolver).to receive(:geocode)
        .with(query: "10 Downing St, London, GB", country_code: "gb", source: :address)
        .and_return(address_resolution)

      result = resolver.resolve(country: "GB", postal_code: "SW1A", address: "10 Downing St, London")

      expect(result.success?).to be(true)
      expect(result.source).to eq(:address)
    end

    it "returns a clear postal-not-found error when postal code has no match and address is missing" do
      resolver = described_class.new

      expect(resolver).to receive(:geocode)
        .with(query: "00000, BR", country_code: "br", source: :postal_code)
        .and_return(nil)

      result = resolver.resolve(country: "BR", postal_code: "00000", address: nil)

      expect(result.success?).to be(false)
      expect(result.error).to eq("Postal code not found for selected country.")
    end
  end
end
