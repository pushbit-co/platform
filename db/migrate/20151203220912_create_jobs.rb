class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.integer    :task_id
      t.string     :slug
      t.string     :status
      t.text       :result
      t.timestamps null: false
    end

    add_index :jobs, :task_id
  end
end
