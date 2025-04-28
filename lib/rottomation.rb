# frozen_string_literal: true

require 'net/http'
require 'json'
require 'time'
require 'selenium-webdriver'

# Require all components of the automation framework
require_relative 'requires'

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
end

# Set default configuration
Rottomation.configure
