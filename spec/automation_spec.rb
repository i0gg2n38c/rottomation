# frozen_string_literal: true

require 'rspec'
require_relative 'spec_helper'
require_relative '../lib/automation'

# Tests
RSpec.describe Automation::AutomationDriverWrapper do # rubocop:disable RSpec/MultipleDescribes
  let(:logger) { Automation::IO::AutomationLogger.new(test_name: described_class.to_s) }
  let(:ldw) { described_class.new(logger: logger) }

  after { ldw.driver_instance&.quit }

  it 'can be created' do
    page = DuckDuckGoHomePage.new driver: ldw
    page.get
    expect(page.driver.driver_instance.title).to include 'DuckDuckGo'
  end
end

RSpec.describe Automation::Pages::BasePage do
  let(:logger) { Automation::IO::AutomationLogger.new test_name: described_class.to_s }
  let(:ldw) { Automation::AutomationDriverWrapper.new logger: logger }

  after { ldw.driver_instance&.quit }

  example 'it can be searched' do # rubocop:disable RSpec/MultipleExpectations,RSpec/ExampleLength
    page = DuckDuckGoHomePage.new driver: ldw
    page.get
    expect(page.driver.driver_instance.title).to include 'DuckDuckGo'
    search = 'bitcoin'
    page.type_search_and_hit_enter(query: search)
    expect(page.driver.driver_instance.title).to eq "#{search} at DuckDuckGo"
  end
end

RSpec.describe Automation::BaseClient do
  let(:logger) { Automation::IO::AutomationLogger.new test_name: described_class.to_s }
  let(:client) do
    described_class.new(logger: logger,
                        auth_type: :basic,
                        uri: 'https://postman-echo.com/',
                        token: 'Basic cG9zdG1hbjpwYXNzd29yZA==') # Provided by Postman for testing
  end

  example 'It can authenticate with Basic Auth' do # rubocop:disable RSpec/NoExpectationExample
    api = PostmanBasicAuthEchoApi.new(client: client)
    client.get api: api
    api.assert_good_response_code
  end

  example 'It can post request bodies' do # rubocop:disable RSpec/NoExpectationExample
    api = PostmanPostEchoApi.new(client: client)
    api.set_request_body request_body: '{"test":"value"}'
    client.post api: api
    api.assert_good_response_code
    logger.log_info log: api.response_json
  end
end

# Demonstration Classes
class DuckDuckGoHomePage < Automation::Pages::BasePage
  def initialize(driver:)
    super(driver: driver, base_url: 'https://duckduckgo.com/')
  end

  def type_search_and_hit_enter(query:)
    wait = Selenium::WebDriver::Wait.new(timeout: 5)
    web_element = @driver.find_elements(xpath: '//input[@id="searchbox_input"]',
                                        element_name: 'search field')
                         .first || raise(IndexError, 'Could not find prose')
    @driver.submit_text(element: web_element, element_name: 'search field', content: query)
    wait.until do
      @driver.find_element(xpath: '//div[@class="results--main"]',
                           element_name: '').displayed?
    end
  end
end

class GoogleHomePage < Automation::Pages::BasePage
  def initialize(driver:)
    super driver: driver, uri: ''
  end
end

class PostmanBasicAuthEchoApi < Automation::BaseApi
  def resource_path
    'basic-auth'
  end
end

class PostmanPostEchoApi < Automation::BaseApi
  def resource_path
    'post'
  end
end
