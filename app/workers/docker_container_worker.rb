module Pushbit
  class DockerContainerWorker < BaseWorker
    def work(id, changed_files, head_sha)
      logger.info "Running Task: #{id}"
      task = Pushbit::Task.find(id)
      task.logs = ""
      repo = task.repo
      image = task.image
      trigger = task.trigger

      logger.info "Using image: #{image.id})"

      container = Docker::Container.create("Image" => image.id,
                                           "Env" => [
                                             "GITHUB_USER=#{repo.github_owner}",
                                             "GITHUB_REPO=#{repo.name}",
                                             "GITHUB_TOKEN=#{ENV.fetch('GITHUB_TOKEN')}",
                                             "GITHUB_NUMBER=#{trigger.payload ? trigger.payload['number'] : nil}",
                                             "BASE_BRANCH=#{head_sha || repo.default_branch || 'master'}",
                                             "CHANGED_FILES=#{changed_files.join(' ')}",
                                             "TASK_ID=#{id}",
                                             "ACCESS_TOKEN=#{task.access_token}",
                                             "APP_URL=#{ENV.fetch('APP_URL')}"
                                           ])

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
        logger.info "Task: #{task.id}: #{line}"
        Task.where(id: task.id).update_all(["logs = logs || ?", line])
      end

      logger.info "CONTAINER JSON: #{container.json}"
      exitcode = container.json['State']['ExitCode']
      task.completed_at = Time.now
      task.status = exitcode == 0 ? :success : :failed
      task.complete!

    rescue Docker::Error::NotFoundError => e
      task.update!(status: :failed,
                   reason: e.message)
      raise e # capture in sentry
    end
  end
end
