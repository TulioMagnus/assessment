require "json"
require "net/http"
require "uri"

class WeatherClient < BaseService
  def call(latitude:, longitude:)
    current_weather(latitude: latitude, longitude: longitude)
  end

  def current_weather(latitude:, longitude:)
    uri = build_uri(latitude: latitude, longitude: longitude)
    response = http_client(uri).request(build_request(uri))
    return failure(error: "Weather service returned #{response.code}.") unless response.is_a?(Net::HTTPSuccess)
    return failure(error: "Weather service returned an empty response.") if response.body.blank?

    payload = JSON.parse(response.body)
    current = payload["current"] || {}
    units = payload["current_units"] || {}
    return failure(error: "Weather data is unavailable for this location.") if current.blank?

    success(
      data: {
        observed_at: current["time"],
        is_day: current["is_day"] == 1,
        temperature: current["temperature_2m"],
        temperature_unit: units["temperature_2m"] || "°C",
        feels_like: current["apparent_temperature"],
        feels_like_unit: units["apparent_temperature"] || "°C",
        humidity: current["relative_humidity_2m"],
        humidity_unit: units["relative_humidity_2m"] || "%",
        precipitation: current["precipitation"],
        precipitation_unit: units["precipitation"] || "mm",
        rain: current["rain"],
        rain_unit: units["rain"] || "mm",
        showers: current["showers"],
        showers_unit: units["showers"] || "mm",
        snowfall: current["snowfall"],
        snowfall_unit: units["snowfall"] || "cm",
        cloud_cover: current["cloud_cover"],
        cloud_cover_unit: units["cloud_cover"] || "%",
        pressure: current["surface_pressure"],
        pressure_unit: units["surface_pressure"] || "hPa",
        wind_speed: current["wind_speed_10m"],
        wind_speed_unit: units["wind_speed_10m"] || "km/h",
        wind_direction: current["wind_direction_10m"],
        wind_direction_unit: units["wind_direction_10m"] || "°",
        wind_gusts: current["wind_gusts_10m"],
        wind_gusts_unit: units["wind_gusts_10m"] || "km/h",
        uv_index: current["uv_index"],
        weather_code: current["weather_code"],
        weather_label: weather_code_label(current["weather_code"])
      }
    )
  rescue JSON::ParserError
    failure(error: "Weather response could not be parsed.")
  rescue SocketError, Timeout::Error, Errno::ECONNREFUSED, Net::ReadTimeout, Net::OpenTimeout
    failure(error: "Weather service is temporarily unavailable.")
  end

  private

  def build_uri(latitude:, longitude:)
    base_url = ENV.fetch("WEATHER_API_BASE_URL", "https://api.open-meteo.com")
    uri = URI("#{base_url}/v1/forecast")
    uri.query = URI.encode_www_form(
      latitude: latitude,
      longitude: longitude,
      current: "temperature_2m,apparent_temperature,relative_humidity_2m,is_day,precipitation,rain,showers,snowfall,cloud_cover,surface_pressure,weather_code,wind_speed_10m,wind_direction_10m,wind_gusts_10m,uv_index",
      timezone: "auto",
      forecast_days: 1
    )
    uri
  end

  def weather_code_label(code)
    {
      0 => "Clear sky",
      1 => "Mainly clear",
      2 => "Partly cloudy",
      3 => "Overcast",
      45 => "Fog",
      48 => "Depositing rime fog",
      51 => "Light drizzle",
      53 => "Moderate drizzle",
      55 => "Dense drizzle",
      61 => "Slight rain",
      63 => "Moderate rain",
      65 => "Heavy rain",
      71 => "Slight snow",
      73 => "Moderate snow",
      75 => "Heavy snow",
      80 => "Slight rain showers",
      81 => "Moderate rain showers",
      82 => "Violent rain showers",
      95 => "Thunderstorm",
      96 => "Thunderstorm with slight hail",
      99 => "Thunderstorm with heavy hail"
    }.fetch(code.to_i, "Unknown")
  end

  def build_request(uri)
    request = Net::HTTP::Get.new(uri)
    request["User-Agent"] = ENV.fetch("WEATHER_USER_AGENT", "avenue-code-forecast/1.0")
    request
  end

  def http_client(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.read_timeout = ENV.fetch("WEATHER_READ_TIMEOUT", "5").to_i
    http.open_timeout = ENV.fetch("WEATHER_OPEN_TIMEOUT", "5").to_i
    http
  end
end
