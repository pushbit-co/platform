class SimplifyTasks < ActiveRecord::Migration
  def change
    drop_table :tasks do;end 

    create_table :tasks do |t|
      t.string      :behavior
      t.integer     :github_id
      t.integer     :repo_id
      t.integer     :trigger_id
      t.timestamps  null: false
    end

    add_index :tasks, :behavior
  end
end
