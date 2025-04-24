# frozen_string_literal: true

require_relative 'support/requires'
require 'config/configuration'
require 'rottomation_logger'

RSpec.configure do |config|
  config.before do
  end

  config.after do
  end
end

def get_client(logger)
  Automation::Mastodon::MastodonClient.new logger: logger, token: 'TOKEN_AUTH_GOES_HERE',
                                           hostname: 'https://{TARGET_WEBBED_SITE}'
end
