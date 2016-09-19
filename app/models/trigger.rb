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

    def src_volume
      "trigger_volume_#{id}"
    end

    def execute!(params = nil)
      TriggerWorker.perform_async(id, params:params)
    end
  end
end
