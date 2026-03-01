require Rails.root.join("app/services/location_resolver")
require Rails.root.join("app/helpers/country_iso_codes")

class ForecastsController < ApplicationController
  helper_method :country_codes

  def new
  end

  def show
    permitted = forecast_params
    @country = permitted[:country].to_s.strip.upcase
    @postal_code = permitted[:postal_code].to_s.strip
    @address = permitted[:address].to_s.strip

    validation_error = validate_inputs
    if validation_error.present?
      @error_message = validation_error
      return render :new, status: :unprocessable_entity
    end

    resolution = ::LocationResolver.new.resolve(
      country: @country,
      postal_code: @postal_code.presence,
      address: @address.presence
    )

    unless resolution.success?
      @error_message = resolution.error
      return render :new, status: :unprocessable_entity
    end

    @resolved_lat = resolution.lat
    @resolved_lon = resolution.lon
    @resolved_postal_code = normalize_postal_code(@postal_code.presence || resolution.postal_code)
    @cache_key = build_cache_key(
      country: @country,
      postal_code: @resolved_postal_code,
      lat: @resolved_lat,
      lon: @resolved_lon
    )
    @resolution_source = resolution.source
  end

  private

  def forecast_params
    params.permit(:country, :postal_code, :address)
  end

  def validate_inputs
    return "Country is required." if @country.blank?
    return "Country must be a 2-letter ISO code." unless @country.match?(/\A[A-Z]{2}\z/)
    return "Country must be a supported ISO code." unless CountryIsoCodes.valid?(@country)
    "Provide postal code or address." if @postal_code.blank? && @address.blank?
  end

  def normalize_postal_code(value)
    value.to_s.strip.upcase.gsub(/\s+/, " ").presence
  end

  def build_cache_key(country:, postal_code:, lat:, lon:)
    if postal_code.present?
      normalized = postal_code.delete(" ").upcase
      return "forecast:#{country}:postal:#{normalized}"
    end

    rounded_lat = lat.to_f.round(2)
    rounded_lon = lon.to_f.round(2)
    "forecast:#{country}:grid:#{rounded_lat}:#{rounded_lon}"
  end

  def country_codes
    CountryIsoCodes.all
  end
end
