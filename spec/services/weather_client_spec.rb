# frozen_string_literal: true

require "rails_helper"

RSpec.describe WeatherClient do
  describe "#current_weather" do
    let(:client) { described_class.new }
    let(:fake_http) { instance_double(Net::HTTP) }

    before do
      allow(client).to receive(:http_client).and_return(fake_http)
    end

    it "returns parsed weather data on success" do
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
      allow(fake_http).to receive(:request).and_return(fake_response)
      allow(fake_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

      result = client.current_weather(latitude: "40.7128", longitude: "-74.0060")

      expect(result.success?).to be(true)
      expect(result.data[:temperature]).to eq(22.4)
      expect(result.data[:temperature_unit]).to eq("°C")
    end

    it "returns failure when upstream responds with non-success status" do
      fake_response = instance_double(Net::HTTPResponse, body: "oops", code: "500")
      allow(fake_http).to receive(:request).and_return(fake_response)
      allow(fake_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)

      result = client.current_weather(latitude: "40.7128", longitude: "-74.0060")

      expect(result.success?).to be(false)
      expect(result.error).to eq("Weather service returned 500.")
    end

    it "returns failure when body is empty" do
      fake_response = instance_double(Net::HTTPSuccess, body: "", code: "200")
      allow(fake_http).to receive(:request).and_return(fake_response)
      allow(fake_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

      result = client.current_weather(latitude: "40.7128", longitude: "-74.0060")

      expect(result.success?).to be(false)
      expect(result.error).to eq("Weather service returned an empty response.")
    end

    it "returns failure when JSON is invalid" do
      fake_response = instance_double(Net::HTTPSuccess, body: "{", code: "200")
      allow(fake_http).to receive(:request).and_return(fake_response)
      allow(fake_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

      result = client.current_weather(latitude: "40.7128", longitude: "-74.0060")

      expect(result.success?).to be(false)
      expect(result.error).to eq("Weather response could not be parsed.")
    end

    it "returns failure when current weather payload is missing" do
      fake_response = instance_double(Net::HTTPSuccess, body: { current: {}, current_units: {} }.to_json, code: "200")
      allow(fake_http).to receive(:request).and_return(fake_response)
      allow(fake_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

      result = client.current_weather(latitude: "40.7128", longitude: "-74.0060")

      expect(result.success?).to be(false)
      expect(result.error).to eq("Weather data is unavailable for this location.")
    end

    it "returns failure when request times out" do
      allow(fake_http).to receive(:request).and_raise(Net::ReadTimeout)

      result = client.current_weather(latitude: "40.7128", longitude: "-74.0060")

      expect(result.success?).to be(false)
      expect(result.error).to eq("Weather service is temporarily unavailable.")
    end
  end
end
