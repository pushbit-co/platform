module Pushbit
  class App < Sinatra::Base
    
    post "/discoveries" do
      authenticate!
      discovery = Discovery.find_or_create_with(params)
      
      status 201
      json :discovery => discovery
    end
    
    get "/discoveries/:identifier" do
      authenticate!
      discovery = Discovery.find_by!(identifier: params['identifier'])
      json :discovery => discovery
    end
    
  end
end
