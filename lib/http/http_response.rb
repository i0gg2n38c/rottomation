# frozen_string_literal: true

module Rottomation
  # Class to represent an Http Request
  class HttpResponse
    attr_reader :code, :headers, :cookies, :body

    def initialize(code:, headers:, cookies:, body:)
      @cookies = {}
      @code = code
      @headers = headers
      @body = body
      cookies&.each do |cookie|
        (name, value) = cookie.split('=')
        @cookies[name] = value
      end
    end

    def parse_body_as_json
      JSON.parse(@body, symbolize_names: true)
    end
  end
end
