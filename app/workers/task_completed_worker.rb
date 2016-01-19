module Pushbit
  class TaskCompletedWorker < BaseWorker
    def work(task_id)
      task = Task.find(task_id)
      if task.has_unactioned_discoveries
        pull_requestable = task.discoveries.unactioned.pull_requestable.length > 0
        has_pull_request = task.trigger.payload && task.trigger.payload["pull_request"]

        if has_pull_request && pull_requestable && task.behavior.actions.include?('pull_request')
          GithubPullRequestWorker.perform_async(task_id)
        elsif has_pull_request && task.behavior.actions.include?('line_comment')
          GithubLineCommentWorker.perform_async(task_id)
        elsif task.behavior.actions.include?('issue')
          GithubIssueWorker.perform_async(task_id)
        end
      end

      task.container.delete(force: true) if task.container
      task.update_attributes({
        container_id: nil,
        container_status: :deleted
      })

      trigger = Trigger.create!(
        kind: "task_completed_#{task.behavior.kind}",
        repo: task.repo
      )
      trigger.execute!
    end
  end
end
