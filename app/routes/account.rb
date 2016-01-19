module Pushbit
  class App < Sinatra::Base
    get "/account" do
      redirect "/account/billing"
    end

    get "/account/billing" do
      authenticate!
      erb :'account/billing'
    end

    get "/account/profile" do
      authenticate!
      erb :'account/profile'
    end
  end
end
