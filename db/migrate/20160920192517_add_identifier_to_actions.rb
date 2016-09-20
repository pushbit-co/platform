class AddIdentifierToActions < ActiveRecord::Migration
  def change
    add_column :actions, :identifier, :string, index: true
  end
end
