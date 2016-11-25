module Pushbit
  class Task < ActiveRecord::Base
    include ActiveModel::MassAssignmentSecurity

    default_scope -> { order('tasks.id DESC') }
    sequential scope: :repo_id

    belongs_to :repo
    belongs_to :trigger
    belongs_to :behavior
    before_update :set_duration

    has_many :actions

    validates :repo, presence: true
    validates :trigger, presence: true
    validates :behavior, presence: true
    validates :status, inclusion: %w(pending created running failed success)
    validates :container_status, allow_blank: true, inclusion: %w(pull create attach start stop restart pause paused unpause resize die destroy)

    def branch
      "pushbit/#{behavior.kind}"
    end

    def triggered_by_login
      if trigger && trigger.triggered_by
        @user ||= User.find_by(github_id: trigger.triggered_by)
        @user ? @user.login : "unknown"
      else
        "pushbit-co"
      end
    end

    def labels
      ["pushbit"]
    end

    def execute!(changed_files = [])
      exitcode = Dockertron.run_task!(self, changed_files)

      self.update_attributes(
        completed_at: Time.now,
        status: exitcode == 0 ? :success : :failed,
      )
    end

    def src_volume
      return nil unless trigger
      trigger.src_volume
    end

    def image
      @image ||= load_image
    end

    def logs=(value)
      # removes unsupported chars from log output (cant be saved in pg)
      write_attribute(:logs, value.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '').delete("\u0000"))
    end

    def access_token
      Digest::MD5.hexdigest "#{ENV.fetch('BASIC_AUTH_SECRET')}#{id}"
    end

    def container
      return nil unless container_id
      Docker::Container.get(container_id)
    end

    private

    def set_duration
      if completed_at && duration == 0
        self.duration = completed_at.to_i - created_at.to_i
      end
    end

    def load_image
      if ENV.fetch("RACK_ENV") == "development"
        puts "in development looking for image by development tag:"
        puts "pushbit-development/#{behavior.kind}:latest"
        if Docker::Image.exist?("pushbit-development/#{behavior.kind}:latest")
          puts "development image found"
          return Docker::Image.get("pushbit-development/#{behavior.kind}:latest")
        end
        puts "development image not found"
      end
      Docker::Image.create('fromImage' => "pushbit/#{behavior.kind}")
    end
  end
end
