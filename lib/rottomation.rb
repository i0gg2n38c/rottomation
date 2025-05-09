# frozen_string_literal: true

require 'net/http'
require 'json'
require 'time'
require 'nokogiri'
require 'selenium-webdriver'

# Require all components of the automation framework
Dir[File.join(File.dirname(__FILE__), '**', '*.rb')].sort.each do |file|
  require file unless File.expand_path(file) == File.expand_path(__FILE__)
end

# Main module for the automation framework
module Rottomation
  class Error < StandardError; end

  VERSION = '0.1.0'

  class << self
    attr_accessor :configuration

    def configure
      self.configuration ||= Rottomation::Config::Configuration.new
      yield(configuration) if block_given?
    end

    def logger
      @logger ||= AutomationLogger.new
    end

    # Reset configuration to defaults
    def reset
      self.configuration = Configuration.new
    end
  end

  def self.normalize_url(url:)
    url.gsub('https://', '').gsub('http://', '').gsub('//', '/')
  end
end

# Set default configuration
Rottomation.configure
