class ForecastsController < ApplicationController
  helper_method :country_codes

  def new
  end

  def show
    input = ::ForecastInput.new(forecast_params)
    assign_input(input)
    unless input.valid?
      @error_message = input.error
      return render :new, status: :unprocessable_entity
    end

    lookup_result = ::ForecastLookup.call(input: input)
    unless lookup_result.success?
      @error_message = lookup_result.error
      return render :new, status: :unprocessable_entity
    end

    assign_result(lookup_result.data)
  end

  private

  def forecast_params
    params.permit(:country, :postal_code, :address, :commit)
  end

  def assign_input(input)
    @country = input.country
    @postal_code = input.postal_code
    @address = input.address
  end

  def assign_result(data)
    @resolved_lat = data[:resolved_lat]
    @resolved_lon = data[:resolved_lon]
    @resolved_postal_code = data[:resolved_postal_code]
    @cache_key = data[:cache_key]
    @resolution_source = data[:resolution_source]
    @weather = data[:weather]
    @weather_from_cache = data[:weather_from_cache]
    @weather_error = data[:weather_error]
  end

  def country_codes
    ::CountryIsoCodes.all
  end
end
