# frozen_string_literal: true

require "rails_helper"

RSpec.describe WeatherClient do
  describe "#current_weather" do
    it "returns parsed weather data on success" do
      client = described_class.new
      fake_response = instance_double(
        Net::HTTPSuccess,
        body: {
          current: {
            time: "2026-03-01T09:00",
            temperature_2m: 22.4,
            apparent_temperature: 23.0,
            precipitation: 0.0,
            weather_code: 1,
            wind_speed_10m: 12.5
          },
          current_units: {
            temperature_2m: "°C",
            apparent_temperature: "°C",
            precipitation: "mm",
            wind_speed_10m: "km/h"
          }
        }.to_json
      )
      fake_http = instance_double(Net::HTTP, request: fake_response)

      allow(client).to receive(:http_client).and_return(fake_http)
      allow(fake_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

      result = client.current_weather(latitude: "40.7128", longitude: "-74.0060")

      expect(result.success?).to be(true)
      expect(result.data[:temperature]).to eq(22.4)
      expect(result.data[:temperature_unit]).to eq("°C")
    end
  end
end
