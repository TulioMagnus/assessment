class WeatherFetcher < BaseService
  def call(cache_key:, latitude:, longitude:)
    weather_data = Rails.cache.fetch("weather:#{cache_key}", expires_in: 30.minutes) do
      client_result = ::WeatherClient.call(latitude: latitude, longitude: longitude)
      raise ::WeatherClient::LookupError, client_result.error unless client_result.success?

      client_result.data
    end

    success(data: weather_data)
  rescue ::WeatherClient::LookupError => e
    failure(error: e.message)
  end
end
