# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'rottomation'
  s.version     = '0.1.0'
  s.summary     = 'Ruby Automation Framework'
  s.description = 'Automation Framework written in Ruby, leveraging Selenium'
  s.authors     = ['dv']
  s.email       = 'email@email.net'
  s.files       = Dir['lib/**/*', 'LICENSE', 'README.md']
  s.homepage    = 'https://github.com/404'
  s.license     = 'MIT'

  s.add_dependency 'money'
  s.add_dependency 'selenium-webdriver'
  s.add_development_dependency 'debase'
  s.add_development_dependency 'parallel_tests'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rubocop-rspec'
  s.add_development_dependency 'ruby-debug-ide'
  s.add_development_dependency 'ruby-lsp-rspec'
end
