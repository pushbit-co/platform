module Pushbit
  class GithubPullRequestWorker < BaseWorker
    def work(task_id)
      task = Task.find(task_id)
      title = pull_request_title(task)
      body = pull_request_body(task)

      # check if the branch we're basing off still has an open PR
      if task.trigger.kind == 'pull_request_opened'
        pr = client.pull_request(task.repo.github_full_name, task.trigger.payload['number'])
        if pr.state != 'open'
          logger.info "Pull request #{task.trigger.payload['number']} no longer open"
          return
        end
      end

      response = client.create_pull_request(
        task.repo.github_full_name,
        base_branch(task),
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

      task.discoveries.pull_requestable.unactioned.update_all(action_id: action.id)
    rescue Octokit::UnprocessableEntity => e
      unless e.message.match 'A pull request already exists'
        raise e # capture in sentry
      end
    end

    private

    class Helpers
      include ViewHelpers
    end

    def base_branch(task)
      if task.trigger.kind == 'pull_request_opened'
        task.trigger.payload['pull_request']['head']['ref']
      else
        task.repo.default_branch || 'master'
      end
    end

    def pull_request_body(task)
      count = task.discoveries.unactioned.length
      template = Tilt.new('./app/actions/pull_request_body.md.erb')
      template.render(Helpers.new, task: task, behavior: task.behavior, count: count)
    end

    def pull_request_title(task)
      count = task.discoveries.unactioned.length
      template = Tilt.new('./app/actions/pull_request_title.md.erb')
      template.render(Helpers.new, task: task, behavior: task.behavior, count: count).strip
    end
  end
end
