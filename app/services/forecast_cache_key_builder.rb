class ForecastCacheKeyBuilder < BaseService
  def call(country:, postal_code:, lat:, lon:)
    if postal_code.present?
      normalized = postal_code.to_s.delete(" ").upcase
      return "forecast:#{country}:postal:#{normalized}"
    end

    rounded_lat = lat.to_f.round(2)
    rounded_lon = lon.to_f.round(2)
    "forecast:#{country}:grid:#{rounded_lat}:#{rounded_lon}"
  end
end
