# frozen_string_literal: true

# require 'base64'

module Rottomation
  class AuthContext
    attr_reader :session_cookies, :token, :username, :password

    def initialize(username: nil, password: nil)
      @username = username
      @password = password
      @token = nil
      @session_cookies = nil
    end

    def with_token(token:)
      @token = token
      self
    end

    def with_session_cookies(session_cookies:)
      @session_cookies = session_cookies
      self
    end

    def basic_auth
      Base64.strict_encode64("Basic #{username}:#{password}")
    end
  end
end
