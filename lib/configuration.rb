# frozen_string_literal: true

require 'yaml'

module Rottomation
  module Config
    # TODO: Document
    # comment
    class Configuration
      class << self
        def config
          @config ||= load_config
        end

        private

        def load_config
          env = ENV['TEST_ENV'] || 'test'
          YAML.load_file(
            File.join(Dir.pwd, "config/environments/#{env}.yml")
          )
        end
      end
    end
  end
end
