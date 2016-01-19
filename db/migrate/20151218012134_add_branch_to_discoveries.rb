class AddBranchToDiscoveries < ActiveRecord::Migration
  def change
    add_column :discoveries, :branch, :string
  end
end
