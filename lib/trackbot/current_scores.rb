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
      top_by(:day_words)
    end

    def best_three_overall
      @best_three_overall ||= top_by(:total_words)
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
        tallies = sum_tallies(participant["tallies"])

        {
          display_name: participant["displayName"],
          **tallies
        }
      end
    end

    def sum_tallies(tallies)
      tallies.each_with_object({ day_words: 0, total_words: 0 }) do |tally, totals|
        next unless tally["measure"] == "word"

        parsed_date = Date.parse(tally["date"])
        next unless parsed_date <= date

        totals[:total_words] += tally["count"]
        totals[:day_words] += tally["count"] if parsed_date == date
      end
    end
  end
end
