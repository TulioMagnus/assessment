class ForecastInput
  attr_reader :country, :postal_code, :address, :error

  def initialize(params = {})
    raw = params.to_h
    @country = raw[:country].to_s.strip.upcase
    @postal_code = raw[:postal_code].to_s.strip
    @address = raw[:address].to_s.strip
    @error = nil
  end

  def valid?
    @error = validation_error
    @error.blank?
  end

  private

  def validation_error
    return "Country is required." if country.blank?
    return "Country must be a 2-letter ISO code." unless country.match?(/\A[A-Z]{2}\z/)
    return "Country must be a supported ISO code." unless ::CountryIsoCodes.valid?(country)
    "Provide postal code or address." if postal_code.blank? && address.blank?
  end
end
