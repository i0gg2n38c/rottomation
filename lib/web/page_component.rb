# frozen_string_literal: true

module Rottomation
  module Pages
    # Top Level Comment
    class PageComponent
      attr_reader :driver, :page

      def initialize(driver:, page:)
        @driver = driver
        @page = page
      end

      def get
        loaded
      end

      private

      def loaded
        raise NotImplementedError, "#{self.class} must implement 'loaded'"
      end
    end
  end
end
