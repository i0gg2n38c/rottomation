# frozen_string_literal: true

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

class PostmanBasicAuthEchoService < Rottomation::HttpService
  def self.get(logger:, auth_context:)
    request = Rottomation::HttpRequestBuilder.new(url: 'https://postman-echo.com/', method_type: :get)
                                             .with_header('Authorization', auth_context.basic_auth)
                                             .build

    execute_request(logger: logger, request: request)
  end
end

class JsonPlaceHolderService < Rottomation::HttpService
  BASE_URL = 'https://jsonplaceholder.typicode.com/'

  def self.posts(logger:)
    resp = fetch_posts(logger: logger)
    json_resp = JSON.parse(resp.body)
    json_resp.map { |entry| Post.new(entry) }
  end

  def self.post(logger:, id:)
    resp = fetch_post(logger: logger, id: id)
    Post.new(JSON.parse(resp.body))
  end

  def self.comments(logger:)
    request = Rottomation::HttpRequestBuilder.new(url: "#{BASE_URL}comments/", method_type: :get)
                                             .build

    resp = execute_request(logger: logger, request: request)
    JSON.parse(resp.body).map { |comment| Comment.new(comment) }
  end

  def self.comments_for_post(logger:, post_id:)
    request = Rottomation::HttpRequestBuilder.new(url: "#{BASE_URL}comments/", method_type: :get)
                                             .with_url_param('postId', post_id)
                                             .build

    resp = execute_request(logger: logger, request: request)
    JSON.parse(resp.body).map { |comment| Comment.new(comment) }
  end

  class Post < Rottomation::Entity
    attr_reader :user_id, :id, :title, :body

    def initialize(post) # rubocop:disable Lint/MissingSuper
      @user_id = post['userId']
      @id = post['id']
      @title = post['title']
      @body = post['body']
    end
  end

  class Comment < Rottomation::Entity
    attr_reader :post_id, :id, :name, :email, :body

    def initialize(comment) # rubocop:disable Lint/MissingSuper
      @post_id = comment['postId']
      @id = comment['id']
      @name = comment['name']
      @email = comment['email']
      @body = comment['body']
    end
  end

  def self.fetch_posts(logger:)
    request = Rottomation::HttpRequestBuilder.new(url: "#{BASE_URL}posts", method_type: :get)
                                             .build
    execute_request(logger: logger, request: request)
  end

  def self.fetch_post(logger:, id:)
    request = Rottomation::HttpRequestBuilder.new(url: "#{BASE_URL}posts/#{id}", method_type: :get)
                                             .build
    execute_request(logger: logger, request: request)
  end

  private_class_method :fetch_posts, :fetch_post
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

  example 'It can authenticate with Basic Auth leveraging a session context' do
    resp = described_class.get(logger: logger, auth_context: context)
    expect(resp.code).to eq 302
    expect(resp.body).to include('Found.')
  end
end

RSpec.describe JsonPlaceHolderService do
  let(:logger) { Rottomation::IO::RottomationLogger.new test_name: described_class.to_s }

  example 'It returns a list of posts' do
    resp = described_class.posts(logger: logger)
    expect(resp[0].id).to eq 1
  end

  example 'It returns a single post' do
    resp = described_class.post(logger: logger, id: 1)
    expect(resp.id).to eq 1
  end

  example 'It returns a single post' do
    resp = described_class.comments_for_post(logger: logger, post_id: 1)
    expect(resp[0].id).to eq 1
  end
end
