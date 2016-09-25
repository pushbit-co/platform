class AddIdentifierToActions < ActiveRecord::Migration
  def change
    add_column :actions, :identifier, :string, index: true
    add_column :actions, :trigger_id, :integer, index: true
  end
end
