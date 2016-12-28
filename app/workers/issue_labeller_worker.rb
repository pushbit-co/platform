require 'set'
require 'ankusa'
require 'ankusa/file_system_storage'

module Pushbit
  class IssueLabellerWorker < BaseWorker
    def work(trigger_id, settings = {})
      trigger = Trigger.find(trigger_id)
      payload = trigger.payload
      repo_full_name = payload['repository']['full_name']
      issue_number = payload['issue']['number']
      issue_title = payload['issue']['title']

      # If the issue is edited and we dont allow labelling on edits
      return if payload['action']['edited'] && !settings['edit']

      # If the issue has already been labelled then lets not edit them
      return if payload['issue']['labels'].size > 0

      # Collect labels available on repo
      labels = client.labels(repo_full_name).map { |l| l.name }

      # Filter labels by settings whitelist if there is one
      if settings['whitelist']
        labels = labels.select { |l| settings['whitelist'].include?(l) }
      end

      # Use trained classifier to suggest label from title
      suggested = suggested_label(issue_title)

      # Add label to issue if within repo labels
      if labels.include?(suggested)
        client.add_labels_to_an_issue(repo_full_name, issue_number, [suggested])
      end
    end

    def suggested_label(text)
      file  = './ml/issue-label-training.txt'
      storage = Ankusa::FileSystemStorage.new(file)
      classifier = Ankusa::NaiveBayesClassifier.new(storage)
      classifier.classify(text)
    end
  end
end
