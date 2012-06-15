ENV["RAILS_ENV"] ||= 'test'
require 'bundler/setup'
require 'rails'
require 'logger'

module Rails
  def self.root
    Pathname.new(File.expand_path('../..', __FILE__))
  end

  def self.logger
    @logger ||= ::Logger.new(STDOUT).tap { |l| l.level = ::Logger::ERROR }
  end
end

require File.expand_path('../../lib/hat-trick', __FILE__)
require 'rspec/autorun'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

RSpec.configure do |config|
  config.mock_with :mocha
end
