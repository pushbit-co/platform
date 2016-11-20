module Pushbit
  class Task < ActiveRecord::Base
    include ActiveModel::MassAssignmentSecurity
    default_scope -> { order('tasks.id DESC') }
  end
end
