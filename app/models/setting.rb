module Pushbit
  class Setting < ActiveRecord::Base
    include ActiveModel::MassAssignmentSecurity

    belongs_to :behavior
  end
end
