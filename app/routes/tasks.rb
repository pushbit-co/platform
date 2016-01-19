module Pushbit
  class App < Sinatra::Base
    get "/tasks" do
      authenticate!
      @tasks = Task.paginate(page: params['page']).where(repo_id: current_user.repos.pluck(:id)).includes(:repo)
      erb :'tasks/index', layout: !request.xhr?
    end

    get "/repos/:id/tasks" do
      authenticate!
      @repo = current_user.repos.find(params['id'])
      @tasks = Task.paginate(page: params['page']).where(repo: @repo).includes(:repo)
      erb :'tasks/index', layout: !request.xhr?
    end

    post "/tasks/:task_id/complete" do
      authenticate!
      Task.find(params["task_id"]).touch(:completed_at)
      200
    end
  end
end
