module Pushbit
  class Dockertron
    def self.clone!(trigger)
      volume_name = "trigger_volume_#{trigger.id}"
      volume = Docker::Volume.create(volume_name)

      head_sha = trigger.payload ? Payload.new(trigger.payload).head_sha : nil
      base_branch = head_sha || trigger.repo.default_branch || 'master'

      Docker::Image.create('fromImage' => 'pushbit/base:latest')
      container = Docker::Container.create({
        "Image" => "pushbit/base",
        "Env" => [
          "SSH_KEY=#{repo.unencrypted_ssh_key}",
          "GITHUB_USER=#{trigger.repo.github_owner}",
          "GITHUB_REPO=#{trigger.repo.name}",
          "GITHUB_NUMBER=#{trigger.payload ? trigger.payload['number'] : nil}",
          "BASE_BRANCH=#{base_branch}",
        ],
        "Volumes" => {
          "/pushbit/code" => {}
        },
        "Entrypoint" => "/bin/bash",
        "Cmd" => "./clone.sh",
        "HostConfig" => {
          "Binds" => [
            "#{volume_name}:/pushbit/code"
          ]
        }
      })

      container.start
      container.attach do |stream, chunk|
        line = "#{stream}: #{chunk}"
        puts "Clone for trigger: #{trigger.id}: #{line}"
      end

      exitcode = container.json['State']['ExitCode']
      puts "Exitcode #{exitcode}"
      puts "Removing clone container"
      container.remove
      volume
    end

    def self.run_task!(task, changed_files, head_sha)
      changed_files = changed_files.map { |f| f['filename'] }
      puts "Running Task: #{task.id}"
      task.logs = ""
      repo = task.repo
      image = task.image
      trigger = task.trigger

      puts "Using image: #{image.id})"

      container = Docker::Container.create({
        "Image" => image.id,
        "Env" => [
          "SSH_KEY=#{repo.unencrypted_ssh_key}",
          "GITHUB_USER=#{repo.github_owner}",
          "GITHUB_REPO=#{repo.name}",
          "GITHUB_NUMBER=#{trigger.payload ? trigger.payload['number'] : nil}",
          "BASE_BRANCH=#{head_sha || repo.default_branch || 'master'}",
          "CHANGED_FILES=#{changed_files.join(' ')}",
          "TASK_ID=#{task.id}",
          "ACCESS_TOKEN=#{task.access_token}",
          "APP_URL=#{ENV.fetch('APP_URL')}"
        ],
        "Volumes" => {
          "/pushbit/code" => {}
        },
        "HostConfig" => {
          "Binds" => [
            "#{trigger.src_volume}:/pushbit/code:ro"
          ]
        }
      })

      container.start
      container.attach do |stream, chunk|
        line = "#{stream}: #{chunk}"
        puts "Task: #{task.id}: #{line}"
        Task.where(id: task.id).update_all(["logs = logs || ?", line])
      end

      exitcode = container.json['State']['ExitCode']
      container.remove
      exitcode
    rescue Docker::Error::NotFoundError => e
      task.update!(status: :failed,
                   reason: e.message)
      raise e # capture in sentry
    end
  end
end
