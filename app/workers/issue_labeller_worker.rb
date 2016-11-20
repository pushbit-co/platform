require 'set'
require 'ankusa'
require 'ankusa/file_system_storage'

module Pushbit
  class IssueLabellerWorker < BaseWorker
    def work(trigger_id)
      trigger = Trigger.find(trigger_id)
      payload = trigger.payload
      repo_full_name = payload['repository']['full_name']
      issue_number = payload['issue']['number']
      issue_title = payload['issue']['title']

      labels = client.labels(repo_full_name).map { |l| l.name }
      suggested = suggested_label(issue_title)

      if labels.include?(suggested)
        client.add_labels_to_an_issue(repo_full_name, issue_number, [suggested])
      end
    end

    def suggested_label(text)
      file  = './ml/training.txt'
      storage = Ankusa::FileSystemStorage.new(file)
      classifier = Ankusa::NaiveBayesClassifier.new(storage)
      classifier.classify(text)
    end
  end
end
