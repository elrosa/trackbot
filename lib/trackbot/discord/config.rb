# frozen_string_literal: true

module Trackbot
  module Discord
    module Config
      WEBHOOK_URL = ENV.fetch("DISCORD_WEBHOOK_URL")
      ALERT_USER_ID = ENV["DISCORD_ALERT_USER_ID"]
    end
  end
end
