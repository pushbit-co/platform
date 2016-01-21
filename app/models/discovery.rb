module Pushbit
  class Discovery < ActiveRecord::Base
    include ActiveModel::MassAssignmentSecurity

    attr_accessible :task_id, :identifier, :kind, :code_changed, :priority, 
                    :title, :message, :path, :line, :column, :length, :branch
    belongs_to :task
    belongs_to :action

    validates :identifier, presence: true
    validates :task, presence: true
    validates :kind, presence: true

    def self.pull_requestable
      where(code_changed: true)
    end

    def self.unactioned
      where(action_id: nil)
    end

    def self.find_or_create_with(attributes)
      disc = find_by(identifier: attributes[:identifier]) || Discovery.new
      disc.update!(attributes)
      disc
    end
  end
end