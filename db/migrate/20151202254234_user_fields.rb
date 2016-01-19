class UserFields < ActiveRecord::Migration
  def change
    add_column :users, :gravatar_id, :string
    add_column :users, :avatar_url, :string
    remove_column :users, :gravitar_id
    
    add_index :users, :github_id
  end
end