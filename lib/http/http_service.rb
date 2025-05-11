# frozen_string_literal: true

module Rottomation
  # Core Service class for building Http Services. Handles the final net.http request building,
  # execution, and processing of the provided Rottomation::HttpRequest object, with automatic
  # logging applied.
  class HttpService
    # Executres the provided request object, logging details about it's execution
    #
    # @param [Rottomation::Logger]
    # @param [Rottomation::HttpRequest]
    # @return [Rottomation::HttpResponse]
    def self.execute_request(logger:, request:)
      url = URI(request.url)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = url.scheme == 'https'
      perform_call(logger:, http:, request:)
    end

    def self.perform_call(logger:, http:, request:)
      logger.log_info log: "Firing request #{request.method_type}"
      logger.log_info log: "  to '#{request.url}'"
      logger.log_info log: "  with headers: #{JSON.pretty_generate(request.headers)}"
      logger.log_info log: "With body: #{request.body}" unless request.body.nil?
      response = http.request(get_net_http_for_request(request:))
      logger.log_info log: "response code: #{response.code}"
      Rottomation::HttpResponse.new(code: response.code.to_i, headers: response.each_header.to_a, body: response.body)
    rescue SocketError => e
      logger.log_info log: "Failed to connect: #{e.message}"
      raise e
    rescue Timeout::Error => e
      logger.log_info log: "Request timed out: #{e.message}"
      raise e
    rescue StandardError => e
      logger.log_info log: "An error occurred: #{e.message}"
      raise e
    end

    # Takes the given Rottomation::HttpRequest object and returns a prepared net.HTTP object.
    # @param [Rottomation::HttpRequest]
    # @return [Net::HTTP]
    def self.get_net_http_for_request(request:)
      api = case request.method_type
            when :get then Net::HTTP::Get.new(request.url)
            when :post then Net::HTTP::Post.new(request.url)
            when :put then Net::HTTP::Put.new(request.url)
            when :patch then Net::HTTP::Patch.new(request.url)
            when :delete then Net::HTTP::Delete.new(request.url)
            else
              raise ArgumentError, "Invalid HTTP method: #{request.method_type}"
            end

      request.headers.each do |key, val|
        api[key] = val
      end

      api.body = request.body.to_json if json_content_type?(request:)
      api.set_form_data(request.body) if html_form_content_type?(request:)
      api
    end

    def self.json_content_type?(request:)
      request.headers.any? do |name, value|
        name.to_s.downcase == 'content-type' && value.to_s.downcase.include?('application/json')
      end
    end

    def self.html_form_content_type?(request:)
      request.headers.any? do |name, value|
        name.to_s.downcase == 'content-type' && value.to_s.downcase.include?('application/x-www-form-urlencoded')
      end
    end

    private_class_method :perform_call, :get_net_http_for_request, :json_content_type?, :html_form_content_type?
  end
end
