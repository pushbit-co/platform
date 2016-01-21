module Pushbit
  class CloneRepoWorker < BaseWorker

    # TODO: we can store payload against trigger and avoid passing head_sha
    # task.execute!(changed_files, payload.head_sha)
    # logger.info "Starting task #{task.id} (#{behavior.name}) for #{repo.github_full_name}"
  end
end

