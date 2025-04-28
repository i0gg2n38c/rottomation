# frozen_string_literal: true

module Rottomation
  class HttpResponse
    attr_reader :code, :headers, :body

    def initialize(code:, headers:, body:)
      @code = code
      @headers = headers
      @body = body
    end
  end
end
