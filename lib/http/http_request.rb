# frozen_string_literal: true

module Rottomation
  class HttpRequest
    attr_reader :url, :method_type, :headers, :body

    def initialize(url:, method_type:, headers:, body:)
      @url = url
      @method_type = method_type
      @headers = headers
      @body = body
    end
  end
end
