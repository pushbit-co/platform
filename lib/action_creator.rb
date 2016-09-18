module Pushbit
  class ActionCreator
    attr_reader :repo, :task

    def initialize(repo, task)
      @repo = repo
      @task = task
    end

    def self.issue(repo, task, data)
      new(repo, task).issue(data)
    end

    def self.pull_request(repo, task, data)
      new(repo, task).pull_request(data)
    end

    def issue(repo, task, data)

    end

    def pull_request(repo, task, params)
      title = params[:title]
      body = params[:body]

      response = client.create_pull_request(
        repo.github_full_name,
        params[:base_branch],
        task.branch,
        title,
        body,
        labels: task.labels.join(",")
      )

      # TODO: some checks n stuff
      action = Action.create!({
        kind: 'pull_request',
        title: title,
        body: body,
        repo_id: task.repo_id,
        task_id: task.id,
        github_id: response.id,
        github_url: response.html_url
      }, without_protection: true)
      action
    rescue Octokit::UnprocessableEntity => e
      unless e.message.match 'A pull request already exists'
        raise e # capture in sentry
      end
    end

    def client
      @client ||= Octokit::Client.new(:access_token => ENV.fetch("GITHUB_TOKEN"))
    end
  end
end
