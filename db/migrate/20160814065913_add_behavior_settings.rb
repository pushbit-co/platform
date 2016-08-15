class AddBehaviorSettings < ActiveRecord::Migration
  def change
    create_table :settings do |t|
      t.integer    :repo_behavior_id
      t.string     :key
      t.string     :value
      t.timestamps null: false
    end

    add_index :settings, [:repo_behavior_id, :key], unique: true
  end
end
