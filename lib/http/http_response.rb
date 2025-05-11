# frozen_string_literal: true

module Rottomation
  # Class to represent an Http Request
  class HttpResponse
    attr_reader :code, :headers, :body

    def initialize(code:, headers:, body:)
      @code = code
      @headers = headers
      @body = body
    end

    # Takes the provided HttpResponse entity headers and collects the cookies into a Hash
    # @return [Hash] Hash of the collected 'set-cookie' headers.
    def parse_cookies_from_headers
      cookies = {}
      @headers.each do |header_name, cookie|
        next unless header_name == 'set-cookie'

        (k, v) = cookie.split('=')
        cookies[k] = v
      end
      cookies
    end
  end
end
