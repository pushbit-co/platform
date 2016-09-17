class AddLocationToDiscoveries < ActiveRecord::Migration
  def change
    add_column :discoveries, :path, :string
    add_column :discoveries, :line, :integer
    add_column :discoveries, :column, :integer
    add_column :discoveries, :length, :integer
    
    add_column :repos, :default_branch, :string
    
    add_column :triggers, :payload, :string
  end
end
