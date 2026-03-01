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
    @resolved_postal_code = resolved_postal_code_for(resolution)
    @cache_key = ::ForecastCacheKeyBuilder.call(
      country: @country,
      postal_code: @resolved_postal_code,
      lat: @resolved_lat,
      lon: @resolved_lon
    )
    @resolution_source = resolution.source
    weather_result = ::WeatherFetcher.call(
      cache_key: @cache_key,
      latitude: @resolved_lat,
      longitude: @resolved_lon
    )
    if weather_result.data.is_a?(Hash) && weather_result.data.key?(:weather)
      @weather = weather_result.data[:weather]
      @weather_from_cache = weather_result.data[:from_cache]
    else
      @weather = weather_result.data
      @weather_from_cache = nil
    end
    @weather_error = weather_result.error
  end

  private

  def forecast_params
    params.permit(:country, :postal_code, :address, :commit)
  end

  def validate_inputs
    return "Country is required." if @country.blank?
    return "Country must be a 2-letter ISO code." unless @country.match?(/\A[A-Z]{2}\z/)
    return "Country must be a supported ISO code." unless ::CountryIsoCodes.valid?(@country)
    "Provide postal code or address." if @postal_code.blank? && @address.blank?
  end

  def normalize_postal_code(value)
    value.to_s.strip.upcase.gsub(/\s+/, " ").presence
  end

  def resolved_postal_code_for(resolution)
    code = if resolution.postal_code.present?
      resolution.postal_code
    elsif resolution.source.to_s == "postal_code"
      @postal_code
    end

    normalize_postal_code(code)
  end

  def country_codes
    ::CountryIsoCodes.all
  end
end
