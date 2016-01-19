class TaskLogs < ActiveRecord::Migration
  def change
    add_column :tasks, :logs, :text
    add_column :tasks, :container_status, :string
    
    add_index :tasks, :container_id
    add_index :tasks, :repo_id
  end
end