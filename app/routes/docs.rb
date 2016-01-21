module Pushbit
  class App < Sinatra::Base
    get "/docs" do
      erb :'docs/index', layout: :docs
    end

    get "/docs/*" do
      erb :"docs/#{params['splat'].first}", layout: :docs
    end
  end
end
