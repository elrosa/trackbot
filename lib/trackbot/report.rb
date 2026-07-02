# frozen_string_literal: true

require_relative "current_scores"
require_relative "discord/client"

module Trackbot
  class Report
    attr_reader :scores, :discord_client

    def initialize
      @scores = Trackbot::CurrentScores.new
      @discord_client = Trackbot::Discord::Client.new
    end

    def call
      discord_client.send_message(daily_message)
      post_monthly_winner
    end

    def no_leaderboard
      discord_client.send_message(
        <<~MESSAGE.strip
          **TrackBot** could not find a leaderboard for current month.

          Magdaleno, ogarnij się!
        MESSAGE
      )
    end

    private

    def post_monthly_winner
      return unless Config.today.day == 1

      winner = scores.best_overall
      return unless winner

      sleep 1
      discord_client.send_embed(monthly_winner_embed(winner))
    end

    def daily_message
      <<~MESSAGE.strip
        **#{scores.leaderboard_title}**

        **Yesterday's top writers**
        #{format_rankings(scores.best_three_yesterday, :day_tally)}

        **Overall standings** (through #{format_date(scores.date)})
        #{format_rankings(scores.best_three_overall, :total_tally)}
      MESSAGE
    end

    def monthly_winner_embed(winner)
      {
        title: "🏆 #{scores.date.strftime("%B")} champion",
        description: <<~DESC.strip,
          ## #{winner[:display_name]}
          #{winner[:total_tally]} words total

          Congratulations! You won naming rights to next month's leaderboard!
          (and a big pat on the back)
        DESC
        color: 0xFFD700
      }
    end

    def format_rankings(rows, tally_key)
      return "_No scores yet._" if rows.empty?

      rows.map.with_index do |row, index|
        "#{(index + 1)}. #{row[:display_name]} - #{row[tally_key]} words"
      end.join("\n")
    end

    def format_date(date)
      date.strftime("%B %-d, %Y")
    end
  end
end
