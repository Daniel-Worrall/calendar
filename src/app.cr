require "./calendar"
require "kemal"
require "./geolite/geolite"

geloite = Geolite.new("GeoLite2-City.mmdb")

client = Calendar::Client.new(ENV["CLIENT_ID"], ENV["CLIENT_SECRET"], ENV["ACCESS_TOKEN"], ENV["EXPIRES_IN"], ENV["REFRESH_TOKEN"], ENV["SCOPE"])
id = ENV["CALENDAR_ID"].not_nil!

get "/" do |env|
  env.response.content_type = "application/rss+xml"
  timezone = Time::Location::UTC
  if ip = env.request.remote_address.try &.split(":").first
    timezone = geloite.timezone(ip)
  end
  client.rss(id, timezone)
end

Kemal.run
