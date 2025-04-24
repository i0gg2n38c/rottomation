# frozen_string_literal: true

module Automation
  module Errors
    # Base error class for all automation errors
    class AutomationError < StandardError
    end

    class IllegalStateException < AutomationError
      attr_reader :additional_info

      def initialize(msg = 'Illegal State Exception: ', additional_info = nil)
        @additional_info = additional_info
        super(msg)
      end
    end

    class AssertResponseError < AutomationError
      attr_reader :additional_info

      def initialize(msg = 'Resonse Error: ', additional_info = nil)
        @additional_info = additional_info
        super(msg)
      end
    end

    class PageLoadException < AutomationError
      attr_reader :additional_info

      def initialize(msg = 'Page failed to load', additional_info = nil)
        @additional_info = additional_info
        super(msg)
      end
    end
  end
end
