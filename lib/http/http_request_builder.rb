# frozen_string_literal: true

module Rottomation
  class HttpRequestBuilder
    def initialize(url:, method_type:)
      @url = url
      @method_type = method_type
      @headers = {}
      @url_params = {}
      @body = nil
      @cookies = {}
    end

    def with_header(name, value)
      @headers[name] = value
      self
    end

    def with_headers(headers_hash)
      @headers.merge!(headers_hash)
      self
    end

    def with_url_param(name, value)
      @url_params[name] = value
      self
    end

    def with_url_params(params_hash)
      @url_params.merge!(params_hash)
      self
    end

    def with_body(body)
      @body = body
      self
    end

    def with_json_body(data)
      @body = JSON.generate(data)
      with_header('Content-Type', 'application/json')
    end

    def with_cookie(name, value)
      @cookies[name] = value
      self
    end

    def with_session_cookies(cookies_hash)
      @cookies.merge!(cookies_hash)
      self
    end

    def build
      # Apply cookies to headers
      unless @cookies.empty?
        cookie_string = @cookies.map { |name, value| "#{name}=#{value}" }.join('; ')
        @headers['Cookie'] = cookie_string
      end

      # Build the final URL with parameters
      url = @url
      unless @url_params.empty?
        query_string = @url_params.map do |name, value|
          "#{URI.encode_www_form_component(name.to_s)}=#{URI.encode_www_form_component(value.to_s)}"
        end.join('&')
        url += (url.include?('?') ? '&' : '?') + query_string
      end

      # Return a hash representing the request
      Rottomation::HttpRequest.new(url: url, method_type: @method_type, headers: @headers, body: @body)
    end

    def base_url(url)
      @url = url
      self
    end
  end
end
