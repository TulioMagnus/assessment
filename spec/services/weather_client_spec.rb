# frozen_string_literal: true

require "rails_helper"

RSpec.describe WeatherClient do
  describe "#call" do
    let(:client) { described_class }

    it "returns parsed weather data on success" do
      fake_response = instance_double(
        Net::HTTPSuccess,
        body: {
          current: {
            time: "2026-03-01T09:00",
            is_day: 1,
            temperature_2m: 22.4,
            apparent_temperature: 23.0,
            relative_humidity_2m: 61,
            precipitation: 0.0,
            rain: 0.0,
            showers: 0.0,
            snowfall: 0.0,
            cloud_cover: 18,
            surface_pressure: 1013.2,
            weather_code: 1,
            wind_speed_10m: 12.5,
            wind_direction_10m: 185,
            wind_gusts_10m: 18.0,
            uv_index: 2.4
          },
          current_units: {
            is_day: "",
            temperature_2m: "°C",
            apparent_temperature: "°C",
            relative_humidity_2m: "%",
            precipitation: "mm",
            rain: "mm",
            showers: "mm",
            snowfall: "cm",
            cloud_cover: "%",
            surface_pressure: "hPa",
            wind_speed_10m: "km/h",
            wind_direction_10m: "°",
            wind_gusts_10m: "km/h",
            uv_index: ""
          }
        }.to_json
      )
      allow(HttpGetClient).to receive(:call).and_return(fake_response)
      allow(fake_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

      result = client.call(latitude: "40.7128", longitude: "-74.0060")

      expect(result.success?).to be(true)
      expect(result.data[:temperature]).to eq(22.4)
      expect(result.data[:temperature_unit]).to eq("°C")
      expect(result.data[:humidity]).to eq(61)
      expect(result.data[:weather_label]).to eq("Mainly clear")
    end

    it "returns failure when upstream responds with non-success status" do
      fake_response = instance_double(Net::HTTPResponse, body: "oops", code: "500")
      allow(HttpGetClient).to receive(:call).and_return(fake_response)
      allow(fake_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)

      result = client.call(latitude: "40.7128", longitude: "-74.0060")

      expect(result.success?).to be(false)
      expect(result.error).to eq("Weather service returned 500.")
    end

    it "returns failure when body is empty" do
      fake_response = instance_double(Net::HTTPSuccess, body: "", code: "200")
      allow(HttpGetClient).to receive(:call).and_return(fake_response)
      allow(fake_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

      result = client.call(latitude: "40.7128", longitude: "-74.0060")

      expect(result.success?).to be(false)
      expect(result.error).to eq("Weather service returned an empty response.")
    end

    it "returns failure when JSON is invalid" do
      fake_response = instance_double(Net::HTTPSuccess, body: "{", code: "200")
      allow(HttpGetClient).to receive(:call).and_return(fake_response)
      allow(fake_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

      result = client.call(latitude: "40.7128", longitude: "-74.0060")

      expect(result.success?).to be(false)
      expect(result.error).to eq("Weather response could not be parsed.")
    end

    it "returns failure when current weather payload is missing" do
      fake_response = instance_double(Net::HTTPSuccess, body: { current: {}, current_units: {} }.to_json, code: "200")
      allow(HttpGetClient).to receive(:call).and_return(fake_response)
      allow(fake_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

      result = client.call(latitude: "40.7128", longitude: "-74.0060")

      expect(result.success?).to be(false)
      expect(result.error).to eq("Weather data is unavailable for this location.")
    end

    it "returns failure when request times out" do
      allow(HttpGetClient).to receive(:call).and_raise(Net::ReadTimeout)

      result = client.call(latitude: "40.7128", longitude: "-74.0060")

      expect(result.success?).to be(false)
      expect(result.error).to eq("Weather service is temporarily unavailable.")
    end

    it "returns failure when coordinates are missing" do
      result = client.call(latitude: nil, longitude: "-74.0060")

      expect(result.success?).to be(false)
      expect(result.error).to eq("Weather coordinates are missing.")
    end
  end
end
