class CreateTriggers < ActiveRecord::Migration
  def change
    create_table :triggers do |t|
      t.string     :kind
      t.integer    :repo_id
      t.integer    :triggered_by
      
      t.timestamps null: false
    end
    
    remove_column :tasks, :trigger
    remove_column :tasks, :triggered_by
    add_column :tasks, :trigger_id, :integer
    
    add_index :triggers, :repo_id
    add_index :actions, :repo_id
    add_index :actions, :task_id
  end
end
