class AddSettingsToRepoBehaviors < ActiveRecord::Migration
  def change
    add_column :repo_behaviors, :settings, :json
    drop_table :settings
  end
end
