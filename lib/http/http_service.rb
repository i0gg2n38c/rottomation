# frozen_string_literal: true

module Rottomation
  # HttpService - The base Service class used by inheritors.
  # Intent is for each service to be stateless - with all methods in inheritors building a Rottomation::HttpRequest to
  # pass into execute_request
  class HttpService
    def self.execute_request(logger:, request:)
      url = URI(request.url)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = url.scheme == 'https'
      perform_call(logger: logger, http: http, request: request)
    end

    def self.perform_call(logger:, http:, request:) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      logger.log_info log: "Firing request #{request.method_type}"
      logger.log_info log: "  to '#{request.url}'"
      logger.log_info log: "  with headers: #{JSON.pretty_generate(request.headers)}"
      logger.log_info log: "With body: #{request.body}" unless request.body.nil?
      response = http.request(get_net_http_for_request(request: request))
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

      # we should do this based on the content-type of the headers I think.
      api.body = request.body.to_json unless request.body.nil?
      api
    end

    private_class_method :perform_call, :get_net_http_for_request
  end
end
