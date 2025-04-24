# frozen_string_literal: true

require_relative 'rottomation_logger'

module Automation
  module IO
    # Driver Wrapper
    class AutomationDriverWrapper < AutomationLogger
      attr_accessor :environment_url, :grid_hub_url, :driver_instance

      def initialize(test_name:) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        super(test_name: test_name)
        @environment_url = Automation::Config::Configuration.config['environment']['base_url']
        @grid_hub_url = Automation::Config::Configuration.config['selenium']['grid_url']

        log_info log: "Using Environment: #{environment_url}}"
        log_info log: "Using Grid Bub: #{environment_url}}"
        log_info log: 'Laucnhing WebDriver Instance'
        @driver_instance = Selenium::WebDriver.for(:remote,
                                                   url: @grid_hub_url,
                                                   options: Selenium::WebDriver::Firefox::Options.new)

        log_info log: "Using Node: #{@driver_instance.session_id}}"
        @driver_instance.manage.window.maximize
        @driver_instance.manage.timeouts.implicit_wait = 3
        return unless Automation::Config::Configuration.config['environment']['head_on']

        run_head_on(url: @grid_hub_url, driver: @driver_instance)
      end

      def run_head_on(url:, driver:) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
        log_info log: 'Preparing to launch noVNC for node'

        # Fetch the list of nodes from Grid,
        nodes = JSON.parse(Net::HTTP.get(URI("#{url.gsub('/wd/hub', '')}/status")))['value']['nodes']

        # Get the URL for the node of the current driver session
        matched_node = nodes.find do |node|
          node if !node['slots'][0]['session'].nil? && node['slots'][0]['session']['sessionId'] == (driver.session_id)
        end

        if matched_node.nil?
          raise Exception "Could not find matching node URL for provided Session ID: #{@driver.session_id}"
        end

        node_url = matched_node['uri'].gsub(':5555', '')

        log_info log: "Opening noVNC connection on node: #{node_url}"
        system("xdg-open '#{node_url}:7900/?autoconnect=1&resize=scale&password=secret'")

        log_info log: 'Pausing for the driver window to open on the host'
        sleep(3)
      end

      def find_element(element_name:, **kargs)
        log_info(log: "Finding element \"#{element_name}\"")
        log_info(log: '  with args: ')
        log_info(log: "   '#{kargs}'")
        @driver_instance.find_element(kargs)
      end

      def find_elements(element_name:, **kargs)
        log_info(log: "Finding elements \"#{element_name}\"")
        log_info(log: '  with args:')
        log_info(log: "   '#{kargs}'")
        @driver_instance.find_elements(kargs)
      end

      def navigate
        @driver_instance.navigate
      end

      def execute_script(script, *args)
        @driver_instance.execute_script(script, args)
      end

      def current_url
        @driver_instance.current_url
      end

      # Enters the provided content into the element, then hits enter.
      def submit_text(element:, element_name:, content:, additional_chars: '')
        log_info(log: "Sending input \"#{content}\" to field: \"#{element_name}\"")
        element.send_keys(content + additional_chars)
      end

      def wait_for_element(timeout: 3, **kargs)
        wait = Selenium::WebDriver::Wait.new(timeout: timeout)
        wait.until { @driver_instance.find_element(kargs).displayed? }
      end

      def click_element(element_name:, **kargs)
        wait_for_element(kargs).find_element(kargs, element_name: element_name).click
      end
    end
  end
end
