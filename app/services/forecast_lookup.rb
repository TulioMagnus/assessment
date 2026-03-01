class ForecastLookup < BaseService
  attr_reader :input

  def initialize(input:)
    @input = input
  end

  def call
    return failure(error: resolution.error) unless resolution.success?

    weather_data, weather_from_cache = weather_payload_from(weather_result.data)

    success(
      data: {
        country: input.country,
        postal_code: input.postal_code,
        address: input.address,
        resolved_lat: resolution.lat,
        resolved_lon: resolution.lon,
        resolved_postal_code: resolved_postal_code,
        resolution_source: resolution.source,
        cache_key: cache_key,
        weather: weather_data,
        weather_from_cache: weather_from_cache,
        weather_error: weather_result.error
      }
    )
  end

  private

  attr_reader :input

  def resolution
    @resolution ||= ::LocationResolver.new.resolve(
      country: input.country,
      postal_code: input.postal_code.presence,
      address: input.address.presence
    )
  end

  def cache_key
    @cache_key ||= ::ForecastCacheKeyBuilder.call(
      country: input.country,
      postal_code: input.postal_code,
      lat: resolution.lat,
      lon: resolution.lon
    )
  end

  def resolved_postal_code
    @resolved_postal_code ||= resolved_postal_code_for(input: input, resolution: resolution)
  end

  def weather_result
    @weather_result ||= ::WeatherFetcher.call(
      cache_key: cache_key,
      latitude: resolution.lat,
      longitude: resolution.lon
    )
  end

  def normalize_postal_code(value)
    value.to_s.strip.upcase.gsub(/\s+/, " ").presence
  end

  def resolved_postal_code_for(input:, resolution:)
    code = if resolution.postal_code.present?
      resolution.postal_code
    elsif resolution.source.to_s == "postal_code"
      input.postal_code
    end

    normalize_postal_code(code)
  end

  def weather_payload_from(data)
    if data.is_a?(Hash) && data.key?(:weather)
      [ data[:weather], data[:from_cache] ]
    else
      [ data, nil ]
    end
  end
end
