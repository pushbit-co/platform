class AddActionToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :action, :string
  end
end
