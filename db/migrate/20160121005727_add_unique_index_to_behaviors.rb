class AddUniqueIndexToBehaviors < ActiveRecord::Migration
  def change
    remove_index :behaviors, name: 'index_behaviors_on_kind'
    add_index :behaviors, :kind, { unique: true }
  end
end
