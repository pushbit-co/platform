module Pushbit
  class CloneRepoWorker < BaseWorker

    def work(id, params=nil, image="pushbit/base")
      trigger = Trigger.find(id)
      volume = Docker::Volume.create(volume_name(trigger))

      head_sha = trigger.payload ? Payload.new(trigger.payload).head_sha : nil
      container = Docker::Container.create({
        "Image" => image,
        "Env" => [
          "GITHUB_USER=#{trigger.repo.github_owner}",
          "GITHUB_REPO=#{trigger.repo.name}",
          "GITHUB_TOKEN=#{ENV.fetch('GITHUB_TOKEN')}",
          "GITHUB_NUMBER=#{trigger.payload ? trigger.payload['number'] : nil}",
          "BASE_BRANCH=#{head_sha || trigger.repo.default_branch || 'master'}",
          "CHANGED_FILES=#{changed_files(trigger).join(' ')}",
        ],
        "Volumes" => {
          "/pushbit/code" => {}
        }, 
        "Entrypoint" => "/bin/bash",
        "Cmd" => "./clone.sh",
        "HostConfig" => {
          "Binds" => [
            "#{volume_name(trigger)}:/pushbit/code"
          ]
        }
      })

      container.start
      container.attach do |stream, chunk|
        line = "#{stream}: #{chunk}"
        logger.info "Clone for trigger: #{trigger.id}: #{line}"
      end
      exitcode = container.json['State']['ExitCode']

      GithubEventWorker.perform_async(id, params)
    end

    def volume_name(trigger)
      "trigger_volume_#{trigger.id}"
    end

    def changed_files(trigger)
      #TODO remove from docker container worker and this worker and add as a
      #method on trigger
      return [] unless trigger.payload
      payload = Payload.new(trigger.payload)
      return [] unless payload.pull_request_number
      client.pull_request_files(trigger.repo.github_full_name, payload.pull_request_number)
    end
  end
end

