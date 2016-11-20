module Pushbit
  class IssueLabellerWorker < BaseWorker
    def work(trigger_id)
      trigger = Trigger.find(trigger_id)
      payload = trigger.payload
      repo_full_name = payload['repository']['full_name']
      issue_number = payload['issue']['number']
      issue_title = payload['issue']['title']

      labels = client.labels(repo_full_name).map { |l| l.name }
      new_labels = []

      # if labels.include?('bug')

      client.add_labels_to_an_issue(repo_full_name, issue_number, new_labels)
    end
  end
end
