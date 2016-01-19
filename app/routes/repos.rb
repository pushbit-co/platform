module Pushbit
  class App < Sinatra::Base
    post "/repos/:user/:repo/subscribe" do
      authenticate!

      repo = repo_from_params
      Cashier.subscribe(repo, current_user, params['token']) if repo.private?
      Activator.activate(repo, current_user)

      flash[:notice] = "Successfully subscribed #{repo.github_full_name}"
      redirect '/'
    end

    post "/repos/:user/:repo/unsubscribe" do
      authenticate!

      repo = repo_from_params
      Cashier.unsubscribe(repo, current_user) if repo.private?
      Activator.deactivate(repo, current_user)

      flash[:notice] = "Successfully unsubscribed #{repo.github_full_name}"
      redirect '/'
    end

    get "/repos/:user/:repo/trigger" do
      authenticate!

      repo = repo_from_params
      trigger = Trigger.create!(
        kind: "manual",
        repo: repo,
        triggered_by: current_user.github_id
      )
      trigger.execute!

      flash[:notice] = "Successfully triggered all behaviors"
      redirect back
    end

    get "/repos" do
      authenticate!

      erb :'repos/index', layout: !request.xhr?
    end

    get "/repos/:user/:repo" do
      authenticate!

      @repo = repo_from_params
      @tasks = @repo.tasks.paginate(page: params['page'])
      @actions = Action.paginate(page: params['page']).where(repo_id: @repo.id).includes(:task, :user)
      @title = @repo.github_full_name

      erb :'repos/show'
    end

    get "/repos/:user/:repo/settings" do
      authenticate!

      @repo = repo_from_params
      @behaviors = Behavior.all
      @title = "#{@repo.github_full_name} Settings"

      erb :'repos/settings'
    end

    get "/repos/:user/:repo/:task_sequential_id" do
      authenticate!

      @repo = repo_from_params
      @task = Task.find_by!(repo: @repo, sequential_id: params['task_sequential_id'])
      @events = @task.docker_events
      @actions = @task.actions.map { |a| ActionPresenter.new(a) }
      @title = "Task #{@task.sequential_id}"

      erb :'repos/task'
    end

    delete "/repos/:id" do
      authenticate!

      Repo.find(params["id"]).destroy
      200
    end

    put "/repos/:user/:repo" do
      authenticate!

      repo = repo_from_params
      repo.behaviors = Behavior.where(id: params['behavior_ids']) if params['behavior_ids']
      repo.tags = params['tags'] if params['tags']
      repo.save!

      if params['task_id']
        200
      else
        flash[:notice] = "Updated successfully"
        redirect "/repos/#{repo.github_full_name}"
      end
    end

    private

    def repo_from_params
      if current_user
        current_user.repos.find_by!(github_full_name: "#{params['user']}/#{params['repo']}")
      else
        Task.find(params["task_id"]).repo
      end
    end
  end
end
