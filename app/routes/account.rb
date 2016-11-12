module Pushbit
  class App < Sinatra::Base
    get "/account" do
      redirect "/account/billing"
    end

    get "/account/billing" do
      authenticate!
      @title = "Billing - Account"
      erb :account
    end
  end
end
