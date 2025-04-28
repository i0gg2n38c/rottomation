# frozen_string_literal: true

require 'rspec'
require_relative 'spec_helper'

##############################################################################################################
##################################### Resources ##############################################################
##############################################################################################################
class DuckDuckGoHomePage < Rottomation::Pages::Page
  def initialize(driver:)
    super(driver: driver, base_url: 'https://duckduckgo.com/')
  end

  def type_search_and_hit_enter(query:)
    wait = Selenium::WebDriver::Wait.new(timeout: 5)
    web_element = @driver.find_elements(xpath: '//input[@id="searchbox_input"]',
                                        element_name: 'search field')
                         .first || raise(IndexError, 'Could not find prose')
    @driver.submit_text(element: web_element,
                        element_name: 'search field',
                        content: query,
                        additional_chars: Selenium::WebDriver::Keys[:return])
    wait.until do
      @driver.find_element(xpath: '//div[@class="results--main"]',
                           element_name: '').displayed?
    end
  end
end

class GoogleHomePage < Rottomation::Pages::Page
  def initialize(driver:)
    super driver: driver, uri: ''
  end
end

class PostmanBasicAuthEchoApi < Rottomation::HttpRequest
  def resource_path
    'basic-auth'
  end
end

class PostmanPostEchoApi < Rottomation::HttpRequest
  def resource_path
    'post'
  end
end

class PostmanBasicAuthEchoService < Rottomation::HttpService
  def self.get(logger:, auth_context:)
    request = Rottomation::HttpRequestBuilder.new(url: 'https://postman-echo.com/', method_type: :get)
                                             .with_header('Authorization', auth_context.basic_auth)
                                             .build

    execute_request(logger: logger, request: request)
  end

  def self.get(logger:)
    request = Rottomation::HttpRequestBuilder.new(url: 'https://postman-echo.com/', method_type: :get)
                                             .with_header('Authorization', 'Basic cG9zdG1hbjpwYXNzd29yZA==')
                                             .build

    execute_request(logger: logger, request: request)
  end
end

##############################################################################################################
######################################## Tests ###############################################################
##############################################################################################################
RSpec.describe Rottomation::IO::RottomationDriverWrapper do # rubocop:disable RSpec/MultipleDescribes
  let(:ldw) { described_class.new(test_name: described_class.to_s) }

  after { ldw.driver_instance&.quit }

  it 'can be created' do
    page = DuckDuckGoHomePage.new driver: ldw
    page.get
    expect(page.driver.driver_instance.title).to include 'DuckDuckGo'
  end
end

RSpec.describe Rottomation::Pages::Page do
  let(:ldw) { Rottomation::IO::RottomationDriverWrapper.new test_name: described_class.to_s }

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

RSpec.describe PostmanBasicAuthEchoService do
  let(:logger) { Rottomation::IO::RottomationLogger.new test_name: described_class.to_s }
  let(:context) { Rottomation::AuthContext.new(username: 'postman', password: 'password') }

  example 'It can authenticate with Basic Auth' do
    resp = described_class.get(logger: logger)
    expect(resp.code).to eq 302
    expect(resp.body).to include('Found.')
  end

  example 'It can authenticate with Basic Auth leveraging a session context' do
    resp = described_class.get(logger: logger)
    expect(resp.code).to eq 302
    expect(resp.body).to include('Found.')
  end
end
