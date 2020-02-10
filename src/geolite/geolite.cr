require "geoip2"

class Geolite
  def initialize(filename)
    @reader = GeoIP2.open(filename)
  end

  def timezone(ip)
    Time::Location.load(@reader.city(ip).location.time_zone.to_s)
  rescue GeoIP2::AddressNotFoundError
    Time::Location::UTC
  end
end
