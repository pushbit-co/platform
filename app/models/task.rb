module Pushbit
  class Task < ActiveRecord::Base
    include ActiveModel::MassAssignmentSecurity
    default_scope -> { order('tasks.id DESC') }

    belongs_to :repo
    belongs_to :trigger
  end
end
