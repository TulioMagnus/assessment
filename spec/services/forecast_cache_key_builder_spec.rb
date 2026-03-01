# frozen_string_literal: true

require "rails_helper"

RSpec.describe ForecastCacheKeyBuilder do
  describe ".call" do
    it "builds postal cache key when postal code is present" do
      key = described_class.call(country: "US", postal_code: "33 101", lat: "25.7617", lon: "-80.1918")

      expect(key).to eq("forecast:US:postal:33101")
    end

    it "builds grid cache key when postal code is missing" do
      key = described_class.call(country: "GB", postal_code: nil, lat: "51.5034", lon: "-0.1276")

      expect(key).to eq("forecast:GB:grid:51.5:-0.13")
    end
  end
end
