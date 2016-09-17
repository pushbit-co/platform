module Pushbit
  class Dockertron
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
          "GITHUB_USER=#{repo.github_owner}",
          "GITHUB_REPO=#{repo.name}",
          "GITHUB_TOKEN=#{ENV.fetch('GITHUB_TOKEN')}",
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

      # TODO: what happens to container if this fails
      task.update!(
        container_id: container.id,
        status: :created
      )

      container.start
      task.update!(
        status: :running
      )

      container.attach do |stream, chunk|
        line = "#{stream}: #{chunk}"
        puts "Task: #{task.id}: #{line}"
        Task.where(id: task.id).update_all(["logs = logs || ?", line])
      end

      puts "CONTAINER JSON: #{container.json}"
      exitcode = container.json['State']['ExitCode']
      task.completed_at = Time.now
      task.status = exitcode == 0 ? :success : :failed
      task.save!
      container.remove
    rescue Docker::Error::NotFoundError => e
      task.update!(status: :failed,
                   reason: e.message)
      raise e # capture in sentry
    end
  end
end

