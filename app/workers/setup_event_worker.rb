module Pushbit
  class SetupEventWorker < BaseWorker
    def work(trigger_id)
      trigger = Trigger.find(trigger_id)
      repo = trigger.repo
      behaviors = repo.behaviors.active.trigger('setup')

      behaviors.each do |behavior|
        task = Task.create!({
                              behavior: behavior,
                              repo: repo,
                              trigger: trigger
                            }, without_protection: true)
        task.execute!
        logger.info "Starting task #{task.id} (#{behavior.name}) for #{repo.github_full_name}"
      end
    end
  end
end
