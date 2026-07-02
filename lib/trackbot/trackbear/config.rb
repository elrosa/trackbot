# frozen_string_literal: true

module Trackbot
  module Trackbear
    module Config
      API_BASE_URL = "https://trackbear.app/api/v1"
      API_TOKEN = ENV.fetch("TRACKBEAR_API_TOKEN")
      USER_AGENT = "TrackBot/1.0 (github.com/mzawadzka/trackbot)"
    end
end
end
