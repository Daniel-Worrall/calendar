require "json"
require "http"
require "./googleauth"

module Google
  module DateConverter
    extend self

    def from_json(pull : JSON::PullParser)
      time = nil
      location = nil
      date = false
      pull.read_object do |key|
        case key
        when "dateTime"
          time = Time.new(pull)
        when "date"
          date = true
          time = Time.parse(pull.read_string, "%F", Time::Location::UTC)
        when "timeZone"
          location = Time::Location.load(pull.read_string)
        else
          pull.skip
        end
      end
      if time && location
        time = date ? time.to_local_in(location) : time.in(location)
      end
      time.not_nil!
    end

    def to_json(value : Time, builder : JSON::Builder)
      builder.scalar(value.to_s)
    end
  end

  struct EventList
    include JSON::Serializable

    @[JSON::Field(key: "timeZone")]
    getter timezone : String
    getter items : Array(Event)
  end

  struct Event
    include JSON::Serializable
    # include JSON::Serializable::Unmapped
    getter updated : Time
    getter summary : String

    @[JSON::Field(converter: Google::DateConverter)]
    getter start : Time

    @[JSON::Field(converter: Google::DateConverter)]
    getter end : Time
  end

  extend self

  def get_calendar_list(bearer_token : String, calendar_id : String, from : Time, to : Time)
    params = HTTP::Params.encode({"timeMin" => from.to_rfc3339, "timeMax" => to.to_rfc3339, "singleEvents" => "true", "orderBy" => "startTime"})
    response = HTTP::Client.get("https://www.googleapis.com/calendar/v3/calendars/#{calendar_id}/events?#{params}", HTTP::Headers{"Authorization" => "Bearer #{bearer_token}"})
    EventList.from_json(response.body)
  end
end
