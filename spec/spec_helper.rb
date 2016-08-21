# for autoload paths
$LOAD_PATH << File.expand_path('../../', __FILE__)

require 'rack/test'
require 'rspec'
require 'ostruct'
require 'webmock/rspec'
require 'mock_redis'
require 'docker'
require 'raven'
require 'octokit'
require 'factory_girl'
require 'faker'
require 'sidekiq/testing'
require 'pony'

require_relative 'support/database_cleaner'
require_relative 'support/route_helpers'
require_relative 'support/auth_helpers'

require_relative '../app'

Dir[File.dirname(__FILE__) + "/support/**/*.rb"].each { |f| require f }

ENV['RACK_ENV'] = 'test'

module RSpecMixin
  include Rack::Test::Methods

  def app
    Pushbit::App
  end
end

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.before(:all) do
    Docker.url = "https://10.0.0.1:8090"
  end
  config.before(:each) do
    Sidekiq::Worker.clear_all
  end

  config.include RouteHelpers
  config.include AuthHelpers
  config.include RSpecMixin
end
