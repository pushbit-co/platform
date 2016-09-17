class AddSettingsToBehaviors < ActiveRecord::Migration
  def change
    add_column :behaviors, :settings, :string
  end
end
