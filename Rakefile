require 'sinatra/activerecord/rake'
require 'sinatra/asset_pipeline/task'
require './app'

Sinatra::AssetPipeline::Task.define! Pushbit::App

namespace :db do
  task :load_config do
    require "./app"
  end
end
