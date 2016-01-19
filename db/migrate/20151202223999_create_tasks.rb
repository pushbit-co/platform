class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.integer    :number,        default: 0
      t.integer    :repo_id
      t.string     :container_id
      t.integer    :triggered_by
      t.integer    :duration,      default: 0
      t.string     :commit
      t.string     :authors
      t.string     :status
      t.string     :kind
      t.datetime   :completed_at
      
      t.timestamps null: false
    end
  end
end
