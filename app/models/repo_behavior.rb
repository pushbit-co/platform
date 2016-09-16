module Pushbit
  class RepoBehavior < ActiveRecord::Base
    include ActiveModel::MassAssignmentSecurity

    belongs_to :repo
    belongs_to :behavior
    has_many :settings
  end
end
