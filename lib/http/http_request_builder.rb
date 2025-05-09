# frozen_string_literal: true

module Rottomation
  # Builder class for constructing Rottomation::HttpRequest objects fluently.
  # @example Building a GET request with parameters
  #   request = HttpRequestBuilder.new(url: 'api.example.com/users', method_type: :get)
  #             .with_header('Accept', 'application/json')
  #             .with_url_param('limit', 10)
  #             .build
  class HttpRequestBuilder
    def initialize(url:, method_type:, protocol: 'https://')
      @url = protocol + Rottomation.normalize_url(url: url)
      @method_type = method_type
      @headers = {}
      @url_params = {}
      @body = nil
      @cookies = {}
    end

    # Adds a request header to the request
    #
    # @param name [String] The name of the request header
    # @param value [Object] The value of the request header
    # @return [HttpRequestBuilder] Returns self for method chaining
    def with_header(name, value)
      @headers[name] = value
      self
    end

    # Adds multiple Request Headers to the request by merging the provided hash
    #
    # @param headers_hash [Hash] Hash of request header names and values to add
    # @return [HttpRequestBuilder] Returns self for method chaining
    # @note This method merges with existing parameters rather than replacing them.
    def with_headers(headers_hash)
      @headers.merge!(headers_hash)
      self
    end

    # Adds a URL parameter to the request
    #
    # @param name [String] The name of the URL parameter
    # @param value [Object] The value of the URL parameter
    # @param condition_to_include [Boolean] Whether to include this parameter (default: true)
    # @example Add a parameter only if limit is not nil
    #   with_url_param('limit', limit, condition_to_include: !limit.nil?)
    # @return [HttpRequestBuilder] Returns self for method chaining
    def with_url_param(name, value, condition_to_include: true)
      @url_params[name] = value if condition_to_include
      self
    end

    # Adds multiple URL parameters to the request by merging the provided hash
    #
    # @param params_hash [Hash] Hash of parameter names and values to add
    # @return [HttpRequestBuilder] Returns self for method chaining
    # @note This method merges with existing parameters rather than replacing them.
    def with_url_params(params_hash, condition_to_include: true)
      @url_params.merge!(params_hash) if condition_to_include
      self
    end

    # TODO: Do we need to keep this generic body method?
    # Adds the body to the request object
    #
    # @param body [Object] entity that we are using for the request
    # @return [HttpRequestBuilder] Returns self for method chaining
    # def with_body(body)
    #   @body = body
    #   self
    # end

    # Adds a form body to the request object
    #
    # @param body [Object] entity that we are using for the request
    # @return [HttpRequestBuilder] Returns self for method chaining
    def with_form_body(body)
      @body = body
      with_header('Content-Type', 'application/x-www-form-urlencoded')
      self
    end

    # Adds the body to the request object, specifically as JSON. Additionally, also sets the
    # header 'Content-Type' to 'application/json'
    #
    # @param body [Object] entity that we are using for the request
    # @return [HttpRequestBuilder] Returns self for method chaining
    def with_json_body(data)
      @body = JSON.generate(data)
      with_header('Content-Type', 'application/json')
    end

    # Adds the a cookie to the request.
    #
    # @param name [String] The name of the cookie
    # @param value [String] The value of the cookie
    # @return [HttpRequestBuilder] Returns self for method chaining
    def with_cookie(name, value)
      @cookies[name] = value
      self
    end

    # Adds multiple cookies to the request by merging the provided hash
    #
    # @param cookies_hash [Hash] Hash of parameter names and values to add
    # @return [HttpRequestBuilder] Returns self for method chaining
    # @note This method merges with existing parameters rather than replacing them.
    def with_session_cookies(cookies_hash)
      @cookies.merge!(cookies_hash)
      self
    end

    # Builds the final request object
    #
    # @return [Rottomation::HttpRequest]
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
