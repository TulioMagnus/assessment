require "json"
require "net/http"
require "uri"

class LocationResolver
  Resolution = Struct.new(:lat, :lon, :postal_code, :display_name, :source, :error, keyword_init: true) do
    def success?
      error.blank? && lat.present? && lon.present?
    end
  end

  def resolve(country:, postal_code:, address:)
    country_code = country.to_s.strip.downcase
    return failure("Country is required.") if country_code.blank?

    attempts = []
    attempts << { source: :postal_code, query: "#{postal_code}, #{country}" } if postal_code.present?
    attempts << { source: :address, query: "#{address}, #{country}" } if address.present?

    attempts.each do |attempt|
      geocoded = geocode(query: attempt[:query], country_code: country_code, source: attempt[:source])
      return geocoded if geocoded.present?
    end

    if postal_code.present? && address.blank?
      return failure("Postal code not found for selected country.")
    end

    failure("Address not found for selected country.")
  end

  private

  def geocode(query:, country_code:, source:)
    uri = build_uri(query: query, country_code: country_code)
    response = ::HttpGetClient.call(
      uri: uri,
      user_agent: ENV.fetch("NOMINATIM_USER_AGENT", "avenue-code-forecast/1.0"),
      open_timeout: ENV.fetch("GEOCODER_OPEN_TIMEOUT", "5"),
      read_timeout: ENV.fetch("GEOCODER_READ_TIMEOUT", "5")
    )
    return if !response.is_a?(Net::HTTPSuccess) || response.body.blank?

    payload = JSON.parse(response.body)
    first = payload.first
    return if first.blank?

    Resolution.new(
      lat: first["lat"],
      lon: first["lon"],
      postal_code: first.dig("address", "postcode"),
      display_name: first["display_name"],
      source: source
    )
  rescue JSON::ParserError, SocketError, Timeout::Error, Errno::ECONNREFUSED, Net::ReadTimeout, Net::OpenTimeout
    nil
  end

  def build_uri(query:, country_code:)
    base_url = ENV.fetch("NOMINATIM_BASE_URL", "https://nominatim.openstreetmap.org")
    uri = URI("#{base_url}/search")
    uri.query = URI.encode_www_form(
      q: query,
      format: "jsonv2",
      countrycodes: country_code,
      limit: 1,
      addressdetails: 1
    )
    uri
  end

  def failure(message)
    Resolution.new(error: message)
  end
end
