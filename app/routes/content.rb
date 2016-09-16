module Pushbit
  class App < Sinatra::Base
    get '/pricing' do
      @title = "Pricing"
      erb :pricing
    end

    get '/security' do
      @title = "Security"
      erb :security
    end

    get '/behaviors' do
      @behaviors = Behavior.all
      @title = "Behaviors"

      erb :behaviors
    end
  end
end
