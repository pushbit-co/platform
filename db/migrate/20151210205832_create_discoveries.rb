class CreateDiscoveries < ActiveRecord::Migration
  def change
    create_table :discoveries do |t|
      t.integer    :task_id
      t.integer    :action_id
      t.string     :identifier
      t.boolean    :code_changed, default: false
      t.string     :priority
      t.string     :title
      t.text       :message
      
      t.timestamps null: false
    end
    
    add_index :discoveries, :task_id
    add_index :discoveries, :action_id
    add_index :discoveries, :identifier
  end
end
