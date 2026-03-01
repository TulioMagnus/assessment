class WeatherFetcher < BaseService
  def call(cache_key:, latitude:, longitude:)
    cache_storage_key = "weather:#{cache_key}"
    cached_weather = Rails.cache.read(cache_storage_key)
    unless cached_weather.nil?
      return success(data: { weather: cached_weather, from_cache: true })
    end

    client_result = ::WeatherClient.call(latitude: latitude, longitude: longitude)
    raise ::WeatherClient::LookupError, client_result.error unless client_result.success?

    weather_data = client_result.data
    Rails.cache.write(cache_storage_key, weather_data, expires_in: 30.minutes)

    success(data: { weather: weather_data, from_cache: false })
  rescue ::WeatherClient::LookupError => e
    failure(error: e.message)
  end
end
