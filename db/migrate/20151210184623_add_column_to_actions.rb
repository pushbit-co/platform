class AddColumnToActions < ActiveRecord::Migration
  def change
    add_column :actions, :github_url, :string
  end
end
