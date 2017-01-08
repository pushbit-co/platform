module Pushbit
  class IssueAssignerWorker < BaseWorker
    def work(trigger_id, settings = {})
      trigger = Trigger.find(trigger_id)
      payload = trigger.payload
      repo_full_name = payload['repository']['full_name']
      collaborators = []

      # If the issue has already been assigned then lets not reassign
      return if payload['issue']['assignee'].present?

      # Find possible assignees
      if settings['team']
        collaborators = client.team_members(settings['team'])
      else
        collaborators = client.collaborators(repo_full_name)
      end

      # Filter our bot
      collaborators = collaborators.select { |c| c.login != ENV.fetch('GITHUB_BOT_LOGIN') }

      # Choose one randomly
      collaborator = collaborators.sample
      assignee = collaborator.login

      # Assign Issue
      client.update_issue(repo_full_name, payload['issue']['number'], :assignee => assignee)

      Task.create!({
        behavior: "issue_assigner",
        github_id: payload['issue']['number'],
        trigger_id: trigger_id,
        repo_id: trigger.repo.id
      })
    end
  end
end
