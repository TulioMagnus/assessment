# frozen_string_literal: true

require "rails_helper"

RSpec.describe ForecastInput do
  describe "#valid?" do
    it "normalizes values and validates supported input" do
      input = described_class.new(country: "us", postal_code: " 33101 ", address: " ")

      expect(input.valid?).to be(true)
      expect(input.country).to eq("US")
      expect(input.postal_code).to eq("33101")
      expect(input.address).to eq("")
    end

    it "returns error when country is missing" do
      input = described_class.new(country: "", postal_code: "33101", address: "")

      expect(input.valid?).to be(false)
      expect(input.error).to eq("Country is required.")
    end

    it "returns error when country is unsupported" do
      input = described_class.new(country: "ZZ", postal_code: "33101", address: "")

      expect(input.valid?).to be(false)
      expect(input.error).to eq("Country must be a supported ISO code.")
    end

    it "returns error when both postal code and address are blank" do
      input = described_class.new(country: "US", postal_code: "", address: "")

      expect(input.valid?).to be(false)
      expect(input.error).to eq("Provide postal code or address.")
    end
  end
end
