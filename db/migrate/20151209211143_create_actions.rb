class CreateActions < ActiveRecord::Migration
  def change
    create_table :actions do |t|
      t.string     :kind
      t.integer    :repo_id
      t.string     :container_id
      t.integer    :task_id
      t.integer    :github_id
      
      t.timestamps null: false
    end
  end
end
