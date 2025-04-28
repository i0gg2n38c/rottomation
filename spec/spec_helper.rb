# frozen_string_literal: true

require_relative '../config/configuration'
require_relative '../lib/rottomation'

lib = File.expand_path('../lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

RSpec.configure do |config|
  config.before do
  end

  config.after do
  end
end
