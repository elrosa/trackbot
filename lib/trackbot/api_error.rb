# frozen_string_literal: true

module Trackbot
  class ApiError < StandardError
    attr_reader :code, :status

    def initialize(message, code: nil, status: nil)
      super(message)
      @code = code
      @status = status
    end
  end
end
