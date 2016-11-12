require "base64"

module Pushbit
  class Dockertron
    class << self
      def clone!(trigger)
        Docker::Image.create('fromImage' => 'pushbit/base:latest')

        volume = Docker::Volume.create(trigger.src_volume)
        environment = base_env(trigger)
        container = Docker::Container.create({
          "Image" => "pushbit-development/base",
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


      def run_task!(task, changed_files)
        task.logs = ""

        puts "Running task: #{task.id}"
        puts "Using image: #{task.image.id})"

        environment = base_env(task.trigger).concat task_env(task, changed_files)
        container = Docker::Container.create({
          "Image" => task.image.id,
          "Env" => environment,
          "Volumes" => {
            "/pushbit/code" => {}
          },
          "HostConfig" => {
            "Binds" => [
              "#{task.trigger.src_volume}:/pushbit/code:ro" # note: ro=read-only here
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

      def base_env(trigger)
        [
          "PUSHBIT_BASE64_SSH_KEY=#{Base64.encode64(trigger.repo.unencrypted_ssh_key)}",
          "PUSHBIT_USERNAME=#{trigger.repo.github_owner}",
          "PUSHBIT_REPONAME=#{trigger.repo.name}",
          "PUSHBIT_APP_URL=#{ENV.fetch('APP_URL')}",
          "PUSHBIT_API_URL=#{ENV.fetch('APP_URL')}",
          "PUSHBIT_REPOSITORY_URL=#{trigger.repo.url}"
        ]
      end

      def task_env(task, changed_files)
        trigger = task.trigger
        output = [
          "PUSHBIT_CHANGED_FILES=#{changed_files.join(' ')}",
          "PUSHBIT_TASK_ID=#{task.id}",
          "PUSHBIT_API_TOKEN=#{task.access_token}"
        ]

        if trigger.payload
          payload = Payload.new(trigger.payload)
          base_branch = payload.head_ref || trigger.repo.default_branch || 'master'

          output.concat([
            "PUSHBIT_PR_NUMBER=#{payload.pull_request_number}",
            "PUSHBIT_BASE_COMMIT=#{payload.head_sha}",
            "PUSHBIT_BASE_BRANCH=#{base_branch}"
          ])
        else
          base_branch = trigger.repo.default_branch || 'master'

          output.concat([
            "PUSHBIT_BASE_BRANCH=#{base_branch}"
          ])
        end
      end
    end
  end
end
