# frozen_string_literal: true

require "rails_helper"

RSpec.describe CountryIsoCodes do
  describe ".all" do
    it "returns a list of ISO country codes" do
      expect(described_class.all).to include("US", "BR", "GB")
    end
  end

  describe ".valid?" do
    it "accepts supported country codes case-insensitively" do
      expect(described_class.valid?("us")).to be(true)
      expect(described_class.valid?("BR")).to be(true)
    end

    it "rejects unsupported country codes" do
      expect(described_class.valid?("ZZ")).to be(false)
    end
  end
end
