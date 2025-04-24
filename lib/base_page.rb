# frozen_string_literal: true

module Automation
  module Pages
    # Top Level Comment
    class BasePage
      QUERY_PARSER = URI::Parser.new

      attr_reader :driver, :url

      def initialize(driver:, base_url: nil, uri: '', query: [])
        @driver = driver
        @base_url = base_url
        @url = build_uri_with_query(
          (base_url.nil? ? Automation::Config::Configuration.config['environment']['base_url'] : base_url) + uri,
          query
        )
        @default_wait = Selenium::WebDriver::Wait.new(timeout: 3,
                                                      interval: 0.1,
                                                      ignore: Selenium::WebDriver::Error::StaleElementReferenceError)
      end

      def get
        driver.navigate.to(@url)
        loaded
        self
      end

      protected

      def find_element(element_name:, **locator)
        @driver.wait_for_element(**locator)
        @driver.find_element(**locator, element_name: element_name)
      end

      def find_elements(element_name:, **locator)
        @default_wait.until { !@driver.driver_instance.find_elements(locator).empty? }
        @driver.find_elements(**locator,
                              element_name: element_name)
      end

      def move_to_element(element:, element_name:, should_try_scrolling_up: false) # rubocop:disable Metrics/AbcSize
        @driver.log_info log: "Moving to element: #{element_name}"
        @driver.driver_instance.action.move_to(element).pause.perform
      rescue Selenium::WebDriver::Error::MoveTargetOutOfBoundsError => e
        raise e unless should_try_scrolling_up

        # parse the exception if it's MoveTargetOutOfBoundsError. If the Y coordinate is negative, we might just need 
        # to scroll up a bit for the item to appear again. Namely, self-collapsing headers. This let's this just  
        # automatically attempt to handle it if the item is outside the viewport, we'll scroll until it's in view.
        coordinates = e.message.match(/\((-?\d+), (-?\d+)\)/).captures
        # x = coordinates[0].to_i
        y = coordinates[1].to_i
        raise e unless y.negative?
        @driver.log_info log: "Y coordinate is negative: #{y}, scrolling up and retrying"
        @driver.driver_instance.action.scroll_by(0, -250).pause(duration: 1).perform
        move_to_element(element: element, element_name: element_name, should_try_scrolling_up: false)
      end

      def send_text_and_hit_enter(element:, element_name:, content:)
        @driver.log_info(log: "Sending input \"#{content}\" to field: \"#{element_name}\"")
        @driver.submit_text(element: element, element_name: element_name, content: content,
                            additional_chars: Selenium::WebDriver::Keys::KEYS[:return])
        self
      end

      def set_text(element:, element_name:, content:)
        @driver.log_info(log: "Sending input \"#{content}\" to field: \"#{element_name}\"")
        @driver.submit_text(element: element, element_name: element_name, content: content)
        self
      end

      def click_element(element:, element_name:)
        @driver.log_info(log: "Clicking element #{element_name}")
        @default_wait.until do
            element.click
            true
          rescue Selenium::WebDriver::Error::ElementNotInteractableError
            false
        end
      end

      private

      def loaded
        @default_wait.until { driver.driver_instance.execute_script('return document.readyState') == 'complete' }
        return if driver.current_url.start_with? @url

        raise Automation::Errors::IllegalStateException, "Expected URL #{url}, but got #{driver.current_url}"
      end

      def build_uri_with_query(base_path, query)
        uri = QUERY_PARSER.parse(base_path)
        existing_params = decode_query(uri.query)
        new_params = normalize_query(query)

        uri.query = encode_query(existing_params.merge(new_params))
        uri.to_s
      end

      def normalize_query(query)
        case query
        when String
          decode_query(query)
        when Hash
          query.transform_keys(&:to_s)
        when Array
          query.each_slice(2).to_h
        else
          {}
        end
      end

      def decode_query(query_string)
        return {} if query_string.nil? || query_string.empty?

        Hash[QUERY_PARSER.decode_www_form(query_string)]
      rescue ArgumentError
        {}
      end

      def encode_query(params)
        URI.encode_www_form(params)
      end
    end
  end
end
