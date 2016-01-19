class CreateDockerEvents < ActiveRecord::Migration
  def change
    create_table :docker_events do |t|
      t.integer   :repo_id
      t.integer   :task_id
      t.string    :event_id
      t.string    :container_id
      t.string    :status
      t.timestamps null: false
    end
    
    add_column :tasks, :trigger, :string
    
    add_index :docker_events, :task_id
    add_index :docker_events, :repo_id
    add_index :docker_events, :container_id
  end
end