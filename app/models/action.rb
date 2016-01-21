module Pushbit
  class Action < ActiveRecord::Base
    include ActiveModel::MassAssignmentSecurity
    
    default_scope -> { order('actions.id DESC') }
    
    belongs_to :repo
    belongs_to :task
    belongs_to :user

    has_many :discoveries
    
    validates :kind, presence: true, inclusion: %w(signedup subscribe unsubscribe issue pull_request comment line_comment message)
    
    def self.for_user(user)
      self.where("repo_id IN (?) OR user_id = ?", user.repos.pluck(:id), user.id)
    end
    
    def name
      kind.humanize(capitalize: false)
    end
  end
end
