module Pushbit
  class TaskCompletedEventWorker < BaseWorker
    sidekiq_options retry: false

    def work(trigger_id)
      trigger = Trigger.find(trigger_id)
      repo = trigger.repo
      event = trigger.kind

      behaviors = Behavior.trigger(event).where(id: repo.behaviors.pluck(:id))
      behaviors.each do |behavior|
        task = Task.create!(
          behavior: behavior,
          repo: repo,
          trigger: trigger
        )
        task.execute!
        logger.info "Starting task #{task.id} (#{behavior.name}) for #{repo.github_full_name}"
      end
    end
  end
end
