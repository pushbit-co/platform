module Pushbit
  class App < Sinatra::Base
    get "/actions" do
      authenticate!
      @actions = Action.paginate(page: params['page']).for_user(current_user).includes(:task, :user)
      erb :'actions/index', layout: !request.xhr?
    end

    get "/repos/:id/actions" do
      authenticate!
      @repo = current_user.repos.find(params['id'])
      @actions = Action.paginate(page: params['page']).where(repo: @repo).includes(:task, :user)
      erb :'actions/index', layout: !request.xhr?
    end

    post "/actions" do
      authenticate!

      task = Task.find(params['task_id'])
      action = Action.new(params)
      action.repo = task.repo
      action.save!

      status 201
      json action: action
    end

    put "/actions/:id" do
      authenticate!

      action = Action.find_by!(id: id)
      action.update_attributes!(params)

      json action: action
    end
  end
end