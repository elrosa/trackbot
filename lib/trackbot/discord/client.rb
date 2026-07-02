# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

require_relative "../api_error"
require_relative "config"

module Trackbot
  module Discord
    class Client
      def send_message(content)
        post({content: content})
      end

      def send_embed(embed)
        post(embeds: [embed])
      end

      private

      def post(payload)
        uri = URI(Config::WEBHOOK_URL)
        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "application/json"
        request.body = JSON.generate(payload)

        response = http(uri).request(request)
        return true if response.is_a?(Net::HTTPSuccess)

        raise_error(response)
      end

      def http(uri)
        Net::HTTP.new(uri.host, uri.port).tap do |http|
          http.use_ssl = uri.scheme == "https"
        end
      end

      def raise_error(response)
        status = response.code.to_i
        parsed = JSON.parse(response.body)
        raise ApiError.new(
          parsed["message"] || "Discord webhook request failed",
          code: parsed["code"],
          status: status
        )
      rescue JSON::ParserError
        raise ApiError.new("Discord webhook request failed (HTTP #{status})", status: status)
      end
    end
  end
end
