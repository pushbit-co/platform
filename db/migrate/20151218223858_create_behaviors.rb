class CreateBehaviors < ActiveRecord::Migration
  def change
    create_table :behaviors do |t|
      t.string     :kind
      t.string     :name
      t.string     :tone
      t.string     :discovers
      t.string     :image
      t.text       :description
      t.boolean    :active
      t.string     :triggers,   array: true, default: []
      t.string     :actions,    array: true, default: []
      t.string     :files,      array: true, default: []
      t.string     :tags,       array: true, default: []
    end
    
    create_table :repo_behaviors, id: false do |t|
      t.integer    :behavior_id
      t.integer    :repo_id
    end
    
    add_index :repo_behaviors, [:repo_id, :behavior_id], unique: true
    add_index :behaviors, :kind
    
    add_column :tasks, :behavior_id, :integer
    remove_column :repos, :bots, :string, array: true
  end
end
