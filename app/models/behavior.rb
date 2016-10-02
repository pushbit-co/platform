module Pushbit
  class Behavior < ActiveRecord::Base
    include ActiveModel::MassAssignmentSecurity

    default_scope -> { order('active DESC') }

    scope :any_tags, -> (tags) { where('tags && ARRAY[?]::varchar[]', tags) }
    scope :all_tags, -> (tags) { where('tags @> ARRAY[?]::varchar[]', tags) }
    scope :trigger, -> (trigger) { where('triggers @> ARRAY[?]::varchar[]', trigger) }

    has_many :repos, through: :repo_behaviors
    has_many :tasks

    def execute!(trigger, payload)
      Octokit.auto_paginate = true

      client = Octokit::Client.new(:access_token => ENV.fetch("GITHUB_TOKEN"))
      repo = trigger.repo

      changed_files = []
      # we only read changed files for PR's, perhaps push in the future
      if payload.pull_request_number
        changed_files = client.pull_request_files(repo.github_full_name, payload.pull_request_number)
        changed_files = changed_files.map { |f| f['filename'] }
      end

      if matches_files?(changed_files) || !changed_files
        task = Task.create!({
          behavior: self,
          repo: repo,
          trigger: trigger,
          commit: payload.head_sha
        }, without_protection: true)

        task.execute!(changed_files)
        logger.info "Starting task #{task.id} (#{name}) for #{repo.github_full_name}"
      else
  	    logger.info "#{name} did not match changed files"
      end

      logger.info "execution complete #{trigger.id} for #{trigger.repo.name}"
    end

    def self.active
      where(active: true)
    end

    def self.find_or_create_with(attributes)
      behave = find_by(kind: attributes["kind"]) || Behavior.new
      attributes = attributes.select do |k, _v|
        columns = Behavior.columns.map { |c| c.name.to_sym }
        columns.include? k.to_sym
      end
      behave.update_attributes(attributes, without_protection: true)
      behave
    end

    def matches_files?(changed_files)
      run = false
      return true if !files || files.length == 0

      changed_files.each do |changed|
        files.each do |pattern|
      	  run = true if changed['filename'].match(pattern)
        end
      end

      run
    end
  end
end
