module Pushbit
  class IssueWelcomerWorker < BaseWorker
    def work(trigger_id, settings = {})
      trigger = Trigger.find(trigger_id)
      payload = trigger.payload
      repo_full_name = payload['repository']['full_name']

      # Find all collaborators
      collaborator_logins = client.collaborators(repo_full_name).map(&:login)

      # If this comment is by a collaborator then short circuit
      return if collaborator_logins.include? payload['issue']['user']['login']

      # If this behavior doesn't have a comment configured then there is nothing to say
      return if settings['comment'].empty?

      # Leave a welcome comment!
      client.add_comment(
        repo_full_name,
        payload['issue']['number'],
        settings['comment']
      )
    end
  end
end
