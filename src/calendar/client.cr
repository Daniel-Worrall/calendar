require "./google"
require "xml"

module Calendar
  class Client
    getter calendars = {} of String => Array(Google::Event)
    getter cache = {} of String => Time::Span

    def initialize(client_id : String, client_secret : String, access_token : String, expires_at : String, refresh_token : String, scope : String)
      @googleauth = Google::Auth::TokenStore.new(client_id, client_secret, access_token, expires_at, refresh_token, scope)
    end

    def rss(calendar_id : String, timezone)
      events = cache(calendar_id)
      time = Time.utc

      XML.build do |xml|
        xml.element("rss") do
          xml.element("channel") do
            xml.element("title") { xml.cdata "Calendar Events" }
            xml.element("description") { xml.cdata "Events Synced from Google Calendar" }
            xml.element("ttl") { xml.text "1" }
            events.each do |event|
              xml.element("item") do
                start = event.start.in(timezone)
                span = start - time
                title = String.build do |string|
                  case time
                  when .< start
                    string << span.days
                    string << "d "
                    string << span.hours.to_s.rjust(2, '0')
                    string << "h "
                    string << span.minutes.to_s.rjust(2, '0')
                    string << "m "
                  when .< event.end
                    string << "ONGOING - "
                  else
                    string << "ENDED - "
                  end
                  string << event.summary
                end
                xml.element("title") { xml.cdata title }
                description = String.build do |string|
                  duration = event.end - start
                  start.to_s("%F %R ", string)
                  string << start.zone.name
                  if duration >= Time::Span.new(0, 1, 0)
                    string << " ("
                    if duration.days > 0
                      string << duration.days
                      string << "d "
                    end
                    if duration.hours > 0
                      string << duration.hours
                      string << "h "
                    end
                    if duration.minutes > 0
                      string << duration.minutes
                      string << "m "
                    end
                    string.chomp!(32_u8)
                    string << ")"
                  end
                end
                xml.element("description") { xml.cdata description }
                xml.element("link") { xml.text "test" }
              end
            end
          end
        end
      end
    end

    private def cache(calendar_id)
      if valid_cache?(calendar_id)
        calendars[calendar_id]
      else
        list = events_from_calendar(calendar_id)
        cache[calendar_id] = Time.monotonic
        calendars[calendar_id] = list.items
      end
    end

    private def events_from_calendar(calendar_id : String)
      Google.get_calendar_list(@googleauth.token, calendar_id, Time.utc.at_beginning_of_day, (Time.utc + Time::Span.new(14, 0, 0, 0)))
    end

    private def valid_cache?(calendar_id)
      if time = @cache[calendar_id]?
        Time.monotonic - time < 60.seconds
      end
    end
  end
end
