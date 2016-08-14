module Pushbit
  class App < Sinatra::Base
    post "/repos/:user/:repo/subscribe" do
      authenticate!
      repo = repo_from_params
      authorize! :subscribe, repo

      Cashier.subscribe(repo, current_user, params['token']) if repo.private?
      Activator.activate(repo, current_user)

      flash[:notice] = "Successfully subscribed #{repo.github_full_name}"
      redirect '/'
    end

    post "/repos/:user/:repo/unsubscribe" do
      authenticate!
      repo = repo_from_params
      authorize! :unsubscribe, repo

      Cashier.unsubscribe(repo, current_user) if repo.private?
      Activator.deactivate(repo, current_user)

      flash[:notice] = "Successfully unsubscribed #{repo.github_full_name}"
      redirect '/'
    end

    get "/repos/:user/:repo/trigger" do
      authenticate!
      repo = repo_from_params
      authorize! :trigger, repo

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
      @title = "Repositories"

      erb :'repos/index', layout: !request.xhr?
    end

    get "/repos/:user/:repo" do
      repo = repo_from_params
      authorize! :read, repo

      @repo = repo
      @behaviors = Behavior.all
      @title = @repo.github_full_name

      erb :'repos/show'
    end

    get "/repos/:user/:repo/:behavior" do
      repo = repo_from_params
      authorize! :update, repo

      @repo = repo
      @behavior = repo.behaviors.find_by!(kind: params["behavior"])
      @title = "#{@behavior.name} - #{@repo.github_full_name}"

      erb :'repos/behavior'
    end

    post "/repos/:user/:repo/:behavior" do
      repo = repo_from_params
      authorize! :update, repo

      behavior = repo.behaviors.find_by!(kind: params["behavior"])

      behavior.settings.each do |options, key|
        setting = behavior.setting.find_or_create_by(key: key, behavior: behavior)
        setting.update(value: params["setting_#{key}"])
      end

      flash[:notice] = "Updated successfully"
      redirect "/repos/#{repo.github_full_name}"
    end

    get "/repos/:user/:repo/logs" do
      authenticate!
      repo = repo_from_params
      authorize! :update, repo

      @repo = repo
      @actions = Action.paginate(page: params['page']).where(repo_id: @repo.id).includes(:task, :user)
      @tasks = @repo.tasks.paginate(page: params['page'])
      @title = "Logs - #{@repo.github_full_name}"

      erb :'repos/logs'
    end

    put "/repos/:user/:repo" do
      authenticate!
      repo = repo_from_params
      authorize! :update, repo

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
      if params["task_id"]
        Task.find(params["task_id"]).repo
      else
        Repo.find_by!(github_full_name: "#{params['user']}/#{params['repo']}")
      end
    end
  end
end
