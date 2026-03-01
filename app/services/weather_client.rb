require "json"
require "net/http"
require "uri"

class WeatherClient
  LookupError = Class.new(StandardError)

  Result = Struct.new(:data, :error, keyword_init: true) do
    def success?
      error.blank? && data.present?
    end
  end

  def current_weather(latitude:, longitude:)
    uri = build_uri(latitude: latitude, longitude: longitude)
    response = http_client(uri).request(build_request(uri))
    return Result.new(error: "Weather service returned #{response.code}.") unless response.is_a?(Net::HTTPSuccess)
    return Result.new(error: "Weather service returned an empty response.") if response.body.blank?

    payload = JSON.parse(response.body)
    current = payload["current"] || {}
    units = payload["current_units"] || {}
    return Result.new(error: "Weather data is unavailable for this location.") if current.blank?

    Result.new(
      data: {
        observed_at: current["time"],
        temperature: current["temperature_2m"],
        temperature_unit: units["temperature_2m"] || "°C",
        feels_like: current["apparent_temperature"],
        feels_like_unit: units["apparent_temperature"] || "°C",
        precipitation: current["precipitation"],
        precipitation_unit: units["precipitation"] || "mm",
        wind_speed: current["wind_speed_10m"],
        wind_speed_unit: units["wind_speed_10m"] || "km/h",
        weather_code: current["weather_code"]
      }
    )
  rescue JSON::ParserError
    Result.new(error: "Weather response could not be parsed.")
  rescue SocketError, Timeout::Error, Errno::ECONNREFUSED, Net::ReadTimeout, Net::OpenTimeout
    Result.new(error: "Weather service is temporarily unavailable.")
  end

  private

  def build_uri(latitude:, longitude:)
    base_url = ENV.fetch("WEATHER_API_BASE_URL", "https://api.open-meteo.com")
    uri = URI("#{base_url}/v1/forecast")
    uri.query = URI.encode_www_form(
      latitude: latitude,
      longitude: longitude,
      current: "temperature_2m,apparent_temperature,precipitation,weather_code,wind_speed_10m",
      timezone: "auto",
      forecast_days: 1
    )
    uri
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
