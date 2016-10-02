module Pushbit
  class Dockertron
    class << self
      def clone!(trigger)
        Docker::Image.create('fromImage' => 'pushbit/base:latest')

        volume = Docker::Volume.create(trigger.src_volume)
        environment = env(trigger)
        container = Docker::Container.create({
          "Image" => "pushbit/base",
          "Env" => environment,
          "Volumes" => {
            "/pushbit/code" => {}
          },
          "Entrypoint" => "/bin/bash",
          "Cmd" => "./clone.sh",
          "HostConfig" => {
            "Binds" => [
              "#{trigger.src_volume}:/pushbit/code"
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


      def run_task!(task, changed_files, head_sha)
        changed_files = changed_files.map { |f| f['filename'] }
        task.logs = ""

        puts "Running task: #{task.id}"
        puts "Using image: #{task.image.id})"

        environment = env(task.trigger).concat([
          "CHANGED_FILES=#{changed_files.join(' ')}",
          "TASK_ID=#{task.id}",
          "ACCESS_TOKEN=#{task.access_token}"
        ])

        container = Docker::Container.create({
          "Image" => task.image.id,
          "Env" => environment,
          "Volumes" => {
            "/pushbit/code" => {}
          },
          "HostConfig" => {
            "Binds" => [
              "#{task.trigger.src_volume}:/pushbit/code:ro"
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

      private

      def env(trigger)
        head_sha = trigger.payload ? Payload.new(trigger.payload).head_sha : nil
        pull_request_number = trigger.payload ? Payload.new(trigger.payload).pull_request_number : nil
        base_branch = head_sha || trigger.repo.default_branch || 'master'

        [
          "SSH_KEY=#{trigger.repo.unencrypted_ssh_key}",
          "GITHUB_USER=#{trigger.repo.github_owner}",
          "GITHUB_REPO=#{trigger.repo.name}",
          "GITHUB_NUMBER=#{pull_request_number}",
          "BASE_BRANCH=#{base_branch}",
          "APP_URL=#{ENV.fetch('APP_URL')}"
        ]
      end
    end
  end
end
