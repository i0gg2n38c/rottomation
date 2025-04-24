# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'rottomation'
  s.version     = '0.1.0'
  s.summary     = 'Automation Framework'
  s.description = 'Automation Framework description'
  s.authors     = ['dv']
  s.email       = 'email@email.net'
  s.files       = Dir['lib/**/*', 'LICENSE', 'README.md']
  s.homepage    = 'https://github.com/404'
  s.license     = 'MIT'

  # Runtime dependencies - these are required for the gem to function
  s.add_dependency 'money'
  s.add_dependency 'selenium-webdriver'

  # Development dependencies - these are only needed for development/testing of the gem itself
  s.add_development_dependency 'debase'
  s.add_development_dependency 'parallel_tests'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rubocop-rspec'
  s.add_development_dependency 'ruby-debug-ide'
  s.add_development_dependency 'ruby-lsp-rspec'
end
