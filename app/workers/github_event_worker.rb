module Pushbit
  class GithubEventWorker < BaseWorker
    sidekiq_options retry: false

    def work(trigger_id, data)
      trigger = Trigger.find(trigger_id)
      repo = trigger.repo
      event = trigger.kind
      payload = Payload.new(data)

      # first check to see if we have a ruby handler for this event
      if respond_to?(event)
        public_send(event, trigger, repo, payload)

      # use behavior-based handlers
      else
        behaviors = Behavior.active.trigger(event).where(id: repo.behaviors.pluck(:id))
        Octokit.auto_paginate = true

        # we only read changed files for PR's, perhaps push in the future
        if payload.pull_request_number
          changed_files = client.pull_request_files(repo.github_full_name, payload.pull_request_number)
        end

        tasks = []
        behaviors.each do |behavior|
          if (repo.tags & behavior.tags).length > 0 || behavior.tags.length == 0
            if behavior.matches_files?(changed_files) || !changed_files
              task = Task.create!({
                                    behavior: behavior,
                                    repo: repo,
                                    trigger: trigger,
                                    commit: payload.head_sha
                                  }, without_protection: true)

              # TODO: we can store payload against trigger and avoid passing head_sha
              task.execute!(changed_files, payload.head_sha)
              logger.info "Starting task #{task.id} (#{behavior.name}) for #{repo.github_full_name}"
            else
              logger.info "#{behavior.name} did not match changed files"
            end
          else
            logger.info "#{behavior.tags.join(',')} did not match repo tags (#{repo.tags.join(',')})"
          end
        end
        if tasks.length > 0
          CloneRepoWorker.perform_async(trigger.id)
        end
      end
    end

    def pull_request_closed(_trigger, repo, payload)
      action = Action.find_by(github_id: payload.pull_request_id)
      status = payload.pull_request_merged ? 'merged' : 'closed'

      if action
        action.update_attribute(:github_status, status)
        branch = action.task.branch

        # cleanup after ourselves if we can
        if client.ref(repo.github_full_name, "heads/#{branch}")
          client.delete_branch(repo.github_full_name, branch)
        end
      end
    rescue Octokit::NotFound
    end

    def issue_closed(_trigger, _repo, payload)
      action = Action.find_by(github_id: payload.issue_id)
      action.update_attribute(:github_status, 'closed') if action
    end
  end
end
