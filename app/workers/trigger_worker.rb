module Pushbit
  class TriggerWorker < BaseWorker
    sidekiq_options retry: false

    attr_accessor :trigger, :volume

    def work(id)
      self.trigger = Trigger.find(id)
      if trigger.behaviors.length > 0
        Parallel.each(trigger.behaviors, in_threads: trigger.behaviors.length) do |b|
          b.execute!(trigger)
        end
      else
        logger.info "No behaviors"
      end
    end

    # def clone!
    #   self.volume = Docker::Volume.create(volume_name(trigger))

    #   head_sha = trigger.payload ? Payload.new(trigger.payload).head_sha : nil
    #   Docker::Image.create('fromImage' => 'pushbit/base:latest')
    #   container = Docker::Container.create({
    #     "Image" => "pushbit/base",
    #     "Env" => [
    #       "GITHUB_USER=#{trigger.repo.github_owner}",
    #       "GITHUB_REPO=#{trigger.repo.name}",
    #       "GITHUB_TOKEN=#{ENV.fetch('GITHUB_TOKEN')}",
    #       "GITHUB_NUMBER=#{trigger.payload ? trigger.payload['number'] : nil}",
    #       "BASE_BRANCH=#{head_sha || trigger.repo.default_branch || 'master'}",
    #     ],
    #     "Volumes" => {
    #       "/pushbit/code" => {}
    #     },
    #     "Entrypoint" => "/bin/bash",
    #     "Cmd" => "./clone.sh",
    #     "HostConfig" => {
    #       "Binds" => [
    #         "#{volume_name(trigger)}:/pushbit/code"
    #       ]
    #     }
    #   })

    #   container.start
    #   container.attach do |stream, chunk|
    #     line = "#{stream}: #{chunk}"
    #     logger.info "Clone for trigger: #{trigger.id}: #{line}"
    #   end

    #   exitcode = container.json['State']['ExitCode']
    #   logger.info "Removing clone container"
    #   container.remove
    #   exitcode
    # end

    # def volume_name(trigger)
    #   "trigger_volume_#{trigger.id}"
    # end
  end
end
