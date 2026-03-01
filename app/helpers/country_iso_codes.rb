class CountryIsoCodes
  CODES = %w[
    US CA MX BR AR CL PE CO GB IE FR DE IT ES PT NL BE CH AT SE NO DK FI PL CZ
    SK HU RO BG GR TR UA IN CN JP KR SG AU NZ ZA EG MA NG KE AE SA IL
  ].freeze

  def self.all
    CODES
  end

  def self.normalize(code)
    code.to_s.strip.upcase
  end

  def self.valid?(code)
    CODES.include?(normalize(code))
  end
end
