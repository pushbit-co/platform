module Pushbit
  class Membership < ActiveRecord::Base
    include ActiveModel::MassAssignmentSecurity

    belongs_to :repo
    belongs_to :user
  end
end