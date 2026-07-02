# frozen_string_literal: true

require "date"

module Trackbot
  module Config
    # La Huerta time baby!!
    TIMEZONE = "-04:00"

    def self.today
      Time.now.getlocal(TIMEZONE).to_date
    end

    def self.yesterday
      today - 1
    end
  end
end
