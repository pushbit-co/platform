module Pushbit
  class TriggerWorker < BaseWorker
    sidekiq_options retry: false

    def work(id, data)
      trigger = Trigger.find(id)
      payload = Payload.new(data)

      if trigger.behaviors.length > 0
        logger.info "Cloning codebase"
        volume = Dockertron.clone!(trigger)
        threads = trigger.behaviors.length

        Parallel.each(trigger.behaviors, in_threads: threads) do |behavior|
          behavior.execute!(trigger, payload)
        end

        logger.info "Removing volume"
        volume.remove
      else
        logger.info "No behaviors"
      end
    end
  end
end
