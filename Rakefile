require 'sinatra/activerecord/rake'
require 'sinatra/asset_pipeline/task'
require './app'
require './workers'

Dir.glob('lib/tasks/*.rake').each { |r| load r}

Sinatra::AssetPipeline::Task.define! Pushbit::App

namespace :db do
  task :load_config do
    require "./app"
  end
end
