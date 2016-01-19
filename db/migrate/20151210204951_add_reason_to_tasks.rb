class AddReasonToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :reason, :string
  end
end
