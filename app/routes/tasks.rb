module Pushbit
  class App < Sinatra::Base
    get "/tasks" do
      authenticate!
      @tasks = Task.paginate(page: params['page']).where(repo_id: current_user.repos.pluck(:id)).includes(:repo)
      @title = "Tasks"

      erb :'tasks/index', layout: !request.xhr?
    end

    get "/repos/:id/tasks" do
      repo = Repo.find(params['id'])
      authorize! :read, repo

      @repo = repo
      @tasks = Task.paginate(page: params['page']).where(repo: @repo).includes(:repo)
      @title = "Tasks - #{@repo.github_full_name}"

      erb :'tasks/index', layout: !request.xhr?
    end

    post "/tasks/:task_id/complete" do
      authenticate!
      Task.find(params["task_id"]).touch(:completed_at)
      200
    end
  end
end
