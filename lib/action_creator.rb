module Pushbit
  class ActionCreator
    attr_reader :repo, :task

    def initialize(repo, task)
      @repo = repo
      @task = task
    end

    def self.issue(repo, task, params)
      new(repo, task).issue(params)
    end

    def self.pull_request(repo, task, params)
      new(repo, task).pull_request(params)
    end

    def self.line_comment(repo, task, params)
      new(repo, task).line_comment(params)
    end

    def issue(params)
      task = @task
      title = params[:title]
      body = params[:body]

      response = client.create_issue(
        task.repo.github_full_name,
        title,
        body,
        labels: task.labels.join(",")
      )

      action = Action.create!({
        kind: 'issue',
        title: title,
        body: body,
        repo_id: task.repo_id,
        task_id: task.id,
        github_id: response.id,
        github_url: response.html_url
      }, without_protection: true)

      action
    end

    def pull_request(params)
      repo = @repo
      task = @task
      title = params[:title]
      body = params[:body]

      # check if the branch we're basing off still has an open
      # pull request - if not, then no more work is needed.
      if task.trigger.kind == 'pull_request_opened'
        pr = client.pull_request(task.repo.github_full_name, task.trigger.payload['number'])
        if pr.state != 'open'
          logger.info "Pull request #{task.trigger.payload['number']} no longer open"
          return
        end
      end

      response = client.create_pull_request(
        repo.github_full_name,
        params[:base_branch],
        task.branch,
        title,
        body,
        labels: task.labels.join(",")
      )

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

    def line_comment(params)
      task = @task

      response = client.create_pull_request_comment(
        task.repo.github_full_name,
        task.trigger.payload["number"],
        params["body"],
        task.trigger.payload["pull_request"]["head"]["sha"],
        params["path"],
        params["line"]
      )

      action = Action.create!({
        kind: 'line_comment',
        body: params[:body],
        repo_id: task.repo_id,
        task_id: task.id,
        github_id: response.id,
        github_url: response.html_url
      }, without_protection: true)

      action
    end

    def client
      @client ||= Octokit::Client.new(:access_token => ENV.fetch("GITHUB_TOKEN"))
    end
  end
end
