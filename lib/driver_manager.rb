# frozen_string_literal: true

require 'concurrent'

module Rottomation
  class DriverManager
    @@semaphore = Concurrent::Semaphore.new(Rottomation::Config::Configuration.config['selenium']['grid_node_count'])

    def self.execute_test(test_procedure:, test_name:)
      raise ArgumentError, 'Provided test is not a Proc' unless test_procedure.is_a?(Proc)

      ldw = nil
      begin
        @@semaphore.acquire
        ldw = Rottomation::RottomationDriverWrapper.new(test_name:)
        test_procedure.call(ldw:)
      ensure
        ldw&.driver_instance&.quit
        @@semaphore.release
      end
    end
  end
end
