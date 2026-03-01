require Rails.root.join("app/services/weather_client")

class WeatherFetcher
  Result = Struct.new(:data, :error, keyword_init: true) do
    def success?
      error.blank? && data.present?
    end
  end

  def self.call(cache_key:, latitude:, longitude:)
    weather_data = Rails.cache.fetch("weather:#{cache_key}", expires_in: 30.minutes) do
      client_result = WeatherClient.new.current_weather(latitude: latitude, longitude: longitude)
      raise WeatherClient::LookupError, client_result.error unless client_result.success?

      client_result.data
    end

    Result.new(data: weather_data)
  rescue WeatherClient::LookupError => e
    Result.new(error: e.message)
  end
end
