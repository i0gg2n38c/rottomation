# frozen_string_literal: true

require_relative 'support/requires'
require_relative '../config/configuration'
require_relative '../lib/rottomation'

RSpec.configure do |config|
  config.before do
  end

  config.after do
  end
end

def get_client(logger)
  Rottomation::Mastodon::MastodonClient.new logger: logger, token: 'TOKEN_AUTH_GOES_HERE',
                                           hostname: 'https://{TARGET_WEBBED_SITE}'
end
