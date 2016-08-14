class AddBehaviorSettings < ActiveRecord::Migration
  def change
    create_table :settings do |t|
      t.integer    :behavior_id
      t.string     :key
      t.string     :value
      t.timestamps null: false
    end

    create_table :behavior_settings, id: false do |t|
      t.integer    :behavior_id
      t.integer    :setting_id
    end

    add_index :behavior_settings, [:behavior_id, :setting_id], unique: true
  end
end
