module Pushbit
  class App < Sinatra::Base
    get "/actions" do
      authenticate!

      @actions = Action.paginate(page: params['page']).for_user(current_user).includes(:task, :user)
      @repo_ids = current_user.repos.pluck(:id)
      erb :'actions/index', layout: !request.xhr?
    end

    get "/repos/:id/actions" do
      repo = Repo.find(params['id'])
      authorize! :read, repo

      @repo = repo
      @actions = Action.paginate(page: params['page']).where(repo: @repo).includes(:task, :user)
      @repo_ids = @repo.id

      erb :'actions/index', layout: !request.xhr?
    end

    post "/actions" do
      authenticate!

      task = Task.find(params['task_id'])
      repo = task.repo

      begin
        ac = ActionCreator.new(task, repo)
        action = ac.send(params[:type], params)
        action.save!
      rescue
        status 400
      end

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
