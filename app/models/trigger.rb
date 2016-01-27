module Pushbit
  class Trigger < ActiveRecord::Base
    include ActiveModel::MassAssignmentSecurity

    attr_accessible :kind, :repo, :triggered_by, :payload
    belongs_to :repo
    has_many :tasks
    has_many :actions, through: :tasks

    validates :kind, presence: true

    def user
      @user ||= User.find_by(github_id: triggered_by)
    end

    def execute!(params = nil)
      # Finds the correct worker class based on the trigger name
      # worker = kind.match('task_completed') ? 'task_completed' : kind
      klass = Pushbit.const_get("#{worker.split('_').collect(&:capitalize).join}EventWorker")
      klass.perform_async(id)
    rescue NameError => e
      CloneRepoWorker.perform_async(id, params:params)
    end
  end
end
