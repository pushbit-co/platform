class AddKindToDiscoveries < ActiveRecord::Migration
  def change
    add_column :discoveries, :kind, :string
  end
end
