module Pushbit
  class PullRequestAssignerWorker < BaseWorker
    def work(trigger_id)
      trigger = Trigger.find(trigger_id)
      payload = trigger.payload

      repo_full_name = payload['repository']['full_name']

      #TODO we need to use teams first
      # Find possible assignees, filter our bot
      collaborators = client.collaborators(repo_full_name).select { |c| c.login != ENV.fetch('GITHUB_BOT_LOGIN') }

      puts payload['pull_request']['number']


      # Choose one randomly
      collaborator = collaborators.sample
      assignee = collaborator.login

      # Assign Issue
      client.update_issue(repo_full_name, payload['pull_request']['number'], :assignee => assignee)
    end
  end
end
