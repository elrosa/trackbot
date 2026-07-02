# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

require_relative "../api_error"
require_relative "config"

module Trackbot
  module Trackbear
    class Client
      def ping
        get("/ping/api-token")
      end

      def leaderboards
        get("/leaderboard")
      end

      def leaderboard_participants(uuid)
        get("/leaderboard/#{uuid}/participants")
      end

      private

      def get(path)
        request(Net::HTTP::Get, path)
      end

      def request(request_class, path)
        uri = URI("#{Config::API_BASE_URL}#{path}")
        response = http(uri).request(build_request(request_class, uri))
        parse_response(response)
      end

      def http(uri)
        Net::HTTP.new(uri.host, uri.port).tap do |http|
          http.use_ssl = uri.scheme == "https"
        end
      end

      def build_request(request_class, uri)
        request_class.new(uri).tap do |request|
          request["Authorization"] = "Bearer #{Config::API_TOKEN}"
          request["Accept"] = "application/json"
          request["User-Agent"] = Config::USER_AGENT
        end
      end

      def parse_response(response)
        status = response.code.to_i
        parsed = JSON.parse(response.body)

        unless parsed["success"]
          error = parsed["error"] || {}
          raise ApiError.new(
            error["message"] || "TrackBear API request failed",
            code: error["code"],
            status: status
          )
        end

        unless response.is_a?(Net::HTTPSuccess)
          raise ApiError.new("Unexpected HTTP #{status}", status: status)
        end

        parsed["data"]
      rescue JSON::ParserError
        raise ApiError.new("Invalid JSON response (HTTP #{status})", status: status)
      end
    end
  end
end
