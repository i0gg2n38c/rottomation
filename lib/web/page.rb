# frozen_string_literal: true

module Rottomation
  module Pages
    # Base page class for other pages to inherit from. Centralizes most interactions to limit
    # having to address the driver directly when implementing other page classes.
    class Page
      QUERY_PARSER = URI::Parser.new

      attr_reader :driver, :url

      def initialize(driver:, protocol: nil, base_url: nil, uri: '', query: [])
        protocol = Rottomation::Config::Configuration.config['environment']['protocol'] || 'https://' if protocol.nil?
        @driver = driver
        raw_url = base_url.nil? ? Rottomation::Config::Configuration.config['environment']['base_url'] : base_url
        @base_url = protocol + Rottomation.normalize_url(url: "#{raw_url}#{uri}")
        @url = build_uri_with_query(@base_url, query)
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
        @driver.find_element(**locator, element_name:)
      end

      def find_elements(element_name:, **locator)
        @default_wait.until { !@driver.driver_instance.find_elements(locator).empty? }
        @driver.find_elements(**locator, element_name:)
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
        move_to_element(element:, element_name:, should_try_scrolling_up: false)
      end

      def send_text_and_hit_enter(element:, element_name:, content:)
        @driver.log_info(log: "Sending input \"#{content}\" to field: \"#{element_name}\"")
        @driver.submit_text(element:, element_name:, content:,
                            additional_chars: Selenium::WebDriver::Keys::KEYS[:return])
        self
      end

      def set_text(element:, element_name:, content:)
        @driver.log_info(log: "Sending input \"#{content}\" to field: \"#{element_name}\"")
        @driver.submit_text(element:, element_name:, content:)
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

        raise Rottomation::Errors::IllegalStateException, "Expected URL #{url}, but got #{driver.current_url}"
      end

      def build_uri_with_query(base_path, query)
        uri = QUERY_PARSER.parse(base_path)
        existing_params = decode_query(uri.query)
        new_params = normalize_query(query)

        uri.query = encode_query(existing_params.merge(new_params))
        uri.to_s
      end

      def normalize_query(query)
        return query.to_h if query.respond_to?(:to_h)
        return {} if query.nil?

        URI.decode_www_form(query.to_s).to_h
      rescue StandardError
        {}
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
