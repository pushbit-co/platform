module Pushbit
  class CronEventWorker < BaseWorker
    sidekiq_options retry: false

    def work(trigger_id)
      behaviors = Behavior.trigger('cron')
      behaviors.each do |behavior|

        done_ids = Task.where({
          behavior: behavior
        }).where('completed_at > ?', 24.hours.ago)
          .where.not(status: 'failed')
          .pluck(:repo_id)

        Repo.joins(:repo_behaviors).active.where("repo_behaviors.behavior_id = ?", behavior.id).where.not(id: done_ids).each do |repo|
          task = Task.create!({
            behavior: behavior,
            repo: repo,
            trigger_id: trigger_id
          }, without_protection: true)
          task.execute!
          logger.info "Starting task #{task.id} (#{behavior.name}) for #{repo.github_full_name}"
        end

      end
    end
    
  end
end