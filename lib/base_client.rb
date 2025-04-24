# frozen_string_literal: true

require_relative 'configuration'

module Automation
  # Comment
  class BaseClient
    HTTP_METHODS = %i[get post put patch delete].freeze
    AUTH_TYPES = %i[none basic bearer session_cookie].freeze

    attr_reader :token, :hostname, :logger

    def initialize(logger:, uri:, auth_type:, token: nil, session_cookies: nil)
      @auth_type = auth_type
      unless token.nil?
        @token = case @auth_type
                 when :basic
                   token
                 when :bearer
                   @token.downcase.start_with?('bearer') ? token : "Bearer #{token}"
                 else
                   raise ArgumentError, "Token provided with incompatible authentication type #{@auth_type}"
                 end
      end
      @session_cookies = session_cookies unless session_cookies.nil?

      @hostname = uri.nil? ? Automation::Config::Configuration.config['environment']['base_url'] : uri
      @rate_limit_remaining = 300
      @rate_limit_reset = Time.now
      @logger = logger
      @verbose_logging = Automation::Config::Configuration.config['environment']['verbose_logging']
    end

    HTTP_METHODS.each do |http_method|
      define_method(http_method) do |api:|
        call(api: api, method_type: http_method)
      end
    end

    private

    # Builds and calls a Net::HTTP request using the provided Class<BaseApi>, performing the required steps
    # for the the method_type.
    # @param api [Class<BaseApi>]
    # @param method_type one of [GET, :POST:, :PUT, :PATCH, :DELETE]
    # @return ? < Automation::BaseApi
    def call(api:, method_type:)
      if @rate_limit_remaining.positive?
        @rate_limit_remaining -= 1
      else
        now = Time.now
        @logger.log_warn log: "Approaching rate limit, pausing execution for #{(@rate_limit_reset - now).round(2)} seconds"
        sleep(@rate_limit_reset.to_i - now.to_i)
        @rate_limit_remaining = 300
      end

      # Build the full URL
      url = URI(build_uri(api: api))
      use_ssl = url.scheme == 'https'
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = use_ssl

      # Create the request based on method type
      request = case method_type
                when :get then Net::HTTP::Get.new(url)
                when :post
                  api.headers['Content-Type'] = 'application/json'
                  Net::HTTP::Post.new(url)
                when :put
                  api.headers['Content-Type'] = 'application/json'
                  Net::HTTP::Put.new(url)
                when :patch
                  api.headers['Content-Type'] = 'application/json'
                  Net::HTTP::Patch.new(url)
                when :delete then Net::HTTP::Delete.new(url)
                else
                  raise ArgumentError, "Invalid HTTP method: #{method_type}"
                end

      # Set the headers and request body
      request = set_call_headers(api: api, request: request)
      request.body = api.request_body.to_json unless api.request_body.nil?

      begin
        request_headers = {}
        request.each_header do |key, value|
          request_headers[key] = value
        end
        @logger.log_info log: "Firing request #{method_type}"
        @logger.log_info log: "  to '#{url}'"
        @logger.log_info log: "  with headers: #{JSON.pretty_generate(request_headers)}" if @verbose_logging
        @logger.log_info log: "With body: #{request.body}" unless request.body.nil? || !@verbose_logging
        api.response = http.request(request)
        @logger.log_info log: "response code: #{api.response.code}"
        api
      rescue SocketError => e
        @logger.log_info log: "Failed to connect: #{e.message}"
      rescue Timeout::Error => e
        @logger.log_info log: "Request timed out: #{e.message}"
      rescue StandardError => e
        @logger.log_info log: "An error occurred: #{e.message}"
      ensure
        if !(api.response.nil? || api.response['X-RateLimit-Reset'].nil?) && @verbose_logging
          @rate_limit_limit = api.response['X-RateLimit-Limit']
          @rate_limit_remaining = api.response['X-RateLimit-Remaining'].to_i
          @rate_limit_reset = Time.parse(api.response['X-RateLimit-Reset'])
        end
      end
    end

    def build_uri(api:)
      return "#{api.hostname}#{api.resource_path}" if api.params.empty?

      "#{api.hostname}#{api.resource_path}?#{URI.encode_www_form(api.params)}"
    end

    def set_call_headers(api:, request:)
      api.headers[:authorization] = @token
      api.headers.each do |key, val|
        request[key] = val
      end
      request
    end
  end
end
