unless ENV['RACK_ENV'] == 'ci'
  ENV['RACK_ENV'] = 'test'
end

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
require 'sinatra/activerecord'
require 'protected_attributes'
require 'sequential'

require_relative 'support/database_cleaner'
require_relative 'support/route_helpers'
require_relative '../app'

Dir[File.dirname(__FILE__) + '/support/**/*.rb'].each { |f| require f }

# once database has connected we can set env to 'test' for CI.
ENV['RACK_ENV'] = 'test'

module RSpecMixin
  include Rack::Test::Methods
  include Warden::Test::Helpers

  def app
    Pushbit::App
  end
end

RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
  config.before(:all) do
    Docker.url = 'https://10.0.0.1:8090'
  end
  config.before(:each) do
    Sidekiq::Worker.clear_all
    Warden::Manager.serialize_into_session do |user|
      user.id
    end
    Warden::Manager.serialize_from_session do |id|
      Pushbit::User.get(id)
    end
  end

  config.include RouteHelpers
  config.include RSpecMixin
end
