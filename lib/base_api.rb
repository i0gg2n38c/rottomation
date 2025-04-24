# frozen_string_literal: true

module Automation
  # Base API Class
  class BaseApi
    # private_class_method :new, :allocate
    attr_accessor :response
    attr_reader :client,
                :params,
                :request_body,
                :hostname,
                :headers

    def initialize(client:, params: {})
      @client = client
      @params = params
      @headers = {}
      @request_body = nil
      @hostname = client.hostname
    end

    def update_params(params: {})
      @params = params
    end

    def set_request_body(request_body:)
      @request_body = request_body
    end

    def assert_good_response_code
      raise Automation::Errors::AssertResponseError, 'No response found, did you use call?' if @response.nil?

      unless @response.is_a?(Net::HTTPSuccess)
        raise Automation::Errors::AssertResponseError,
              "Expecting good response code, received: #{@response.code} with body: #{@response.body}"
      end

      self
    end

    def assert_response_code(code)
      raise Automation::Errors::AssertResponseError, 'No response found, did you use call?' if @response.nil?

      unless @response.code == code
        raise Automation::Errors::AssertResponseError,
              "Expecting response code #{code}, received: #{response.code}"
      end

      self
    end

    def response_json
      JSON.parse(@response.body, symbolize_names: true)
    end

    def resource_path
      raise NotImplementedError, "resource_path not implemented for #{self.class}"
    end
  end

  # Provides pagination functionality for API endpoints.
  #
  # Classes that include this module must implement:
  # - {#next_page} - Advances to and returns the next page of results
  # - {#previous_page} - Returns to and returns the previous page of results
  # - {#until_page} - Retrieves all results up to specified page index
  # - {#until_page_end} - Retrieves all results until no more pages exist
  # - {#curr_index} - Returns the current page index
  #
  # @example
  #   class ApiEndpoint
  #     include Paginatable
  #
  #     def next_page
  #       @page_index += 1
  #       fetch_results
  #     end
  #
  #     def curr_index
  #       @page_index
  #     end
  #   end
  #
  # @abstract Implement all methods in including class
  # @since 1.0.0
  module Paginatable
    # Advances to and returns the next page of results
    #
    # @return [Array] Results from the next page
    # @raise [NotImplementedError] If not implemented
    def next_page
      raise NotImplementedError, "#{self.class} must implement 'next_page'"
    end

    # Retrieves all results up to a specified page index
    #
    # @param page_index [Integer] The target page index to paginate until
    # @return [Array] Collection of results up to specified page
    # @raise [NotImplementedError] If not implemented
    def until_page(page_index:)
      raise NotImplementedError, "#{self.class} must implement 'until_page'"
    end

    # Retrieves all results by paginating until no more pages exist
    #
    # @return [Array] Collection of all available results
    # @raise [NotImplementedError] If not implemented
    def until_page_end
      raise NotImplementedError, "#{self.class} must implement 'until_page_end'"
    end

    # Returns to and returns the previous page of results
    #
    # @return [Array] Results from the previous page
    # @raise [NotImplementedError] If not implemented
    def previous_page
      raise NotImplementedError, "#{self.class} must implement 'previous_page'"
    end

    # Returns the current page index
    #
    # @return [Integer] Current page index
    # @raise [NotImplementedError] If not implemented
    def curr_index
      raise NotImplementedError, "#{self.class} must implement 'curr_index'"
    end
  end

  # Provides functionality for fetching and handling response data.
  #
  # Classes that include this module must implement:
  # - {#get_response_data} - Retrieves and processes response data as an entity/list of entities
  #
  # @example
  #   class ApiClient
  #     include ResponseDataFetchable
  #
  #     def get_response_data
  #       response = make_api_call
  #       parse_response(response)
  #     end
  #   end
  #
  # @abstract Implement {#get_response_data} in including class
  # @since 1.0.0
  module ResponseDataFetchable
    # Retrieves response data from the implementing service
    #
    # @abstract
    # @return [Hash] The processed response data
    # @raise [NotImplementedError] If the including class doesn't implement the method
    def response_data
      raise NotImplementedError, "#{self.class} must implement 'response_data'"
    end
  end
end
