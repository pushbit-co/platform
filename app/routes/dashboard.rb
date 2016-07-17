module Pushbit
  class App < Sinatra::Base
    get '/' do
      if current_user
        if current_user.has_active_repos?
          @repos = current_user.repos.active
          erb :dashboard
        else
          @repos = current_user.repos.active
          @pull_requests_opened = Trigger.where(kind: 'pull_request_opened', repo_id: @repos.pluck(:id))
          @pull_requests_merged = Action.where(github_status: 'merged', kind: 'pull_request', repo_id: @repos.pluck(:id))

          if !current_user.onboarding_skipped && (@repos.count < 1 || @pull_requests_opened.count < 1 || @pull_requests_merged.count < 1)
            erb :onboarding
          else
            @tasks = Task.paginate(page: params['page']).where(repo_id: current_user.repos.pluck(:id)).includes(:repo)
            @actions = Action.paginate(page: params['page']).for_user(current_user).includes(:task, :user)
            erb :dashboard
          end
        end
      else
        erb :home
      end
    end

    get '/subscribe' do
      authenticate!

      current_user.sync_repositories!

      if current_user.has_access_to_private_repos?
        @organizations = current_user.client.organizations
      else
        @organizations = []
      end

      @title = "Add Project"
      @id = "subscribe"
      erb :subscribe
    end
  end
end
