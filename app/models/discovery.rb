module Pushbit
  class Discovery < ActiveRecord::Base
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
      disc.update!(attributes, without_protection: true)
      disc
    end
  end
end