# frozen_string_literal: true

module Rottomation
  module IO
    # Default Logger Class
    class RottomationLogger
      attr_reader :test_name

      def initialize(test_name:)
        @test_name = test_name
      end

      def log_info(log:)
        write_log level: LogLevel::INFO, msg: log
      end

      def log_warn(log:)
        write_log level: LogLevel::WARN, msg: log
      end

      def log_error(log:)
        write_log level: LogLevel::ERROR, msg: log
      end

      private

      def write_log(level:, msg:)
        # TODO: Add saving off the output to a file
        puts "[#{level}](#{Time.now.strftime('%Y-%m-%d %H:%M:%S.%L')}) #{@test_name} - #{msg}"
      end
    end

    # Log Level
    module LogLevel
      INFO  = 'INFO'
      WARN  = 'WARN'
      ERROR = 'ERROR'
    end
  end
end
