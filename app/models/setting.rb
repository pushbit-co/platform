module Pushbit
  class Setting < ActiveRecord::Base
    include ActiveModel::MassAssignmentSecurity

    belongs_to :repo_behavior
  end
end
