module Pushbit
  class GithubIssueWorker < BaseWorker
    def work(task_id)
      task = Task.find(task_id)
      title = issue_title(task)
      body = issue_body(task)

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

      task.discoveries.unactioned.update_all(action_id: action.id)
    end

    private

    class Helpers
      include ViewHelpers
    end

    def issue_body(task)
      count = task.discoveries.unactioned.length
      template = Tilt.new('./app/actions/issue_body.md.erb')
      template.render(Helpers.new, task: task, behavior: task.behavior, count: count)
    end

    def issue_title(task)
      count = task.discoveries.unactioned.length
      template = Tilt.new('./app/actions/issue_title.md.erb')
      template.render(Helpers.new, task: task, behavior: task.behavior, count: count).strip
    end
  end
end