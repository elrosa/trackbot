# frozen_string_literal: true

require_relative "config"
require_relative "trackbear/client"

module Trackbot
  class CurrentScores
    class NoCurrentLeaderboardError < StandardError; end

    attr_reader :client, :date

    def initialize
      @client = Trackbot::Trackbear::Client.new
      @date = Config.yesterday
    end

    def leaderboard_title
      current_leaderboard.fetch("title")
    end

    def scores
      @scores ||= participant_scores
    end

    def best_three_yesterday
      top_by(:day_tally)
    end

    def best_three_overall
      @best_three_overall ||= top_by(:total_tally)
    end

    def best_overall
      best_three_overall.first
    end

    private

    def top_by(key, limit: 3)
      scores
        .select { |row| row[key] > 0 }
        .sort_by { |row| -row[key] }
        .first(limit)
    end

    def current_leaderboard
      @current_leaderboard ||= leaderboards.find do |leaderboard|
        from = Date.parse(leaderboard["startDate"])
        to = Date.parse(leaderboard["endDate"])

        (from..to).cover?(date)
      end
    end

    def leaderboards
      @leaderboards ||= @client.leaderboards
    end

    def participants
      @participants ||= begin
        board = current_leaderboard or raise NoCurrentLeaderboardError
        @client.leaderboard_participants(board["uuid"])
      end
    end

    def participant_scores
      participants.map do |participant|
        {
          display_name: participant["displayName"],
          day_tally: day_tally_count(participant),
          total_tally: total_tally_count(participant)
        }
      end
    end

    def day_tally_count(participant)
      participant["tallies"]
        .select { |tally| tally["date"] == date.strftime("%Y-%m-%d") }
        .sum { |tally| tally["count"] }
    end

    def total_tally_count(participant)
      participant["tallies"]
        .select { |tally| Date.parse(tally["date"]) <= date }
        .sum { |tally| tally["count"] }
    end
  end
end
