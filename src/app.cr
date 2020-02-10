require "./calendar"
require "kemal"
require "./geolite/geolite"

timezone = Time::Location.load("America/Denver")

client = Calendar::Client.new(ENV["CLIENT_ID"], ENV["CLIENT_SECRET"], ENV["ACCESS_TOKEN"], ENV["EXPIRES_IN"], ENV["REFRESH_TOKEN"], ENV["SCOPE"], timezone)
id = ENV["CALENDAR_ID"].not_nil!

get "/" do |env|
  env.response.content_type = "application/rss+xml"
  client.rss(id)
end

Kemal.run(ENV["CALENDAR_PORT"].to_i)
