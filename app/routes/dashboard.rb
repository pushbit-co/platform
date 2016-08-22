module Pushbit
  class App < Sinatra::Base
    get '/' do
      if current_user
        if current_user.has_active_repos?
          @repos = current_user.repos.active
          erb :dashboard
        else
          redirect "/connect"
        end
      else
        erb :home
      end
    end

    get '/connect' do
      authenticate!

      current_user.sync_repositories!

      if current_user.has_access_to_private_repos?
        @organizations = current_user.client.organizations
      else
        @organizations = []
      end

      @onboarding = current_user.repos.count <= 0
      @title = "Connect"
      @id = :connect
      erb :connect
    end
  end
end
