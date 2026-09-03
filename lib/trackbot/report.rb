# frozen_string_literal: true

require_relative "current_scores"
require_relative "discord/client"

module Trackbot
  class Report
    attr_reader :scores, :discord_client
    EMPTY_MESSAGES_YESTERDAY = [
      "_No words logged._",
      "_Silence of the drafts_",
      "_\\*crickets\\*_",
      "_\\*tumbleweed\\*_",
      "_Rest day. Best day._",
      "_Plot twist: nobody wrote anything yesterday._",
      "_Fine. \\*sighs\\*. I'll just go write something myself._"
    ].freeze

    EMPTY_MESSAGES_OVERALL = [
      "_Please remain on hold. Our writers will be with you shortly._",
      "_No words written yet._",
      "_The podium is empty._",
      "_No scores yet._",
      "_The month is young and so are ~~we~~ our wordcounts._",
      "_Nothing to see here yet! But the month's not over._",
    ].freeze

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
          **TrackBot** could not find a leaderboard for the current month.

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
        ## #{scores.leaderboard_title}
        ### Yesterday's top writers
        #{format_rankings(scores.best_three_yesterday, :day_words, :day_time)}
        ### Overall standings (through #{format_date(scores.date)})
        #{format_rankings(scores.best_three_overall, :total_words, :total_time)}

      MESSAGE
    end

    def monthly_winner_embed(winner)
      target_month = (scores.date >> 3).strftime("%B")

      {
        title: "#{scores.date.strftime("%B")} champion",
        description: <<~DESC.strip,
          # 👑 #{winner[:display_name]}
          with **#{winner[:total_words]}** words written#{format_time_suffix(winner[:total_time])}!

          You've earned the naming rights for the **#{target_month}** leaderboard!
          *(and a well-deserved pat on the back)*
        DESC
        color: 0xFFD700
      }
    end

    def format_rankings(rows, words_key, time_key)
      if rows.empty?
        return (words_key == :day_words ? EMPTY_MESSAGES_YESTERDAY : EMPTY_MESSAGES_OVERALL).sample
      end

      rows.map.with_index do |row, index|
        "#{index + 1}. **#{row[:display_name]}** - #{row[words_key]} words#{format_time_suffix(row[time_key])}"
      end.join("\n")
    end

    def format_time_suffix(minutes)
      return "" if minutes.nil? || minutes <= 0

      hours = minutes / 60
      mins = minutes % 60
      parts = []
      parts << "#{hours} #{hours == 1 ? "hour" : "hours"}" if hours > 0
      parts << "#{mins} #{mins == 1 ? "minute" : "minutes"}" if mins > 0
      return "" if parts.empty?

      " in #{parts.join(" ")}"
    end

    def format_date(date)
      date.strftime("%B %-d, %Y")
    end
  end
end
