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
      @id = :behaviors

      erb :'repos/show'
    end

    get "/repos/:user/:repo/collaborators" do
      repo = repo_from_params
      authorize! :read, repo
      users = []

      repo.collaborators.each do |user|
        users << {
          id: user.id,
          login: user.login
        }
      end

      json ok: true, collaborators: users
    end

    get "/repos/:user/:repo/teams" do
      repo = repo_from_params
      authorize! :read, repo
      teams = []

      begin
        repo.teams.each do |team|
          teams << {
            id: team.id,
            name: team.name,
            slug: team.slug
          }
        end
      rescue Octokit::NotFound
      end

      json ok: true, teams: teams
    end

    get "/repos/:user/:repo/labels" do
      repo = repo_from_params
      authorize! :read, repo
      labels = []

      begin
        repo.labels.each do |label|
          labels << {
            id: label.id,
            name: label.name
          }
        end
      rescue Octokit::NotFound
      end

      json ok: true, labels: labels
    end

    get "/repos/:user/:repo/activity" do
      authenticate!
      repo = repo_from_params
      authorize! :update, repo

      @repo = repo
      @actions = Action.paginate(page: params['page']).where(repo_id: @repo.id).includes(:task, :user)
      @tasks = @repo.tasks.paginate(page: params['page'])
      @title = "Activity - #{@repo.github_full_name}"

      erb :'repos/activity'
    end

    get "/repos/:user/:repo/:behavior" do
      repo = repo_from_params
      authorize! :update, repo

      @repo = repo
      @behavior = Behavior.find_by!(kind: params["behavior"])
      repo_behavior = repo.repo_behaviors.find_by!(behavior: @behavior)
      @settings = repo_behavior.settings
      @title = "#{@behavior.name} - #{@repo.github_full_name}"

      erb :'repos/behavior'
    end


    post "/repos/:user/:repo/:behavior" do
      authenticate!
      repo = repo_from_params
      authorize! :update, repo

      behavior = Behavior.find_by!(kind: params["behavior"])
      repo_behavior = repo.repo_behaviors.find_by!(behavior: behavior)
      new_settings = repo_behavior.settings || Hash.new

      behavior.settings.each do |(key, options)|
        if params["setting_#{key}"]
          if options["type"] === "boolean"
            new_settings[key] = (params["setting_#{key}"] === "on")
          else
            new_settings[key] = params["setting_#{key}"]
          end
        end
      end

      repo_behavior.update_attribute(:settings, new_settings)
      json success: true
    end

    post "/repos/:user/:repo/:behavior/unsubscribe" do
      authenticate!
      repo = repo_from_params
      authorize! :update, repo

      behavior = Behavior.find_by!(kind: params["behavior"])
      RepoBehavior.where(repo: repo, behavior: behavior).delete_all

      flash[:notice] = "#{behavior.name} no longer enabled for this project"
      redirect "/repos/#{repo.github_full_name}"
    end

    post "/repos/:user/:repo/:behavior/subscribe" do
      authenticate!
      repo = repo_from_params
      authorize! :update, repo

      behavior = Behavior.find_by!(kind: params["behavior"])
      repo.behaviors << behavior
      repo.save!

      flash[:notice] = "#{behavior.name} enabled for this project"
      redirect "/repos/#{repo.github_full_name}"
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
        flash[:notice] = "Settings updated"
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
