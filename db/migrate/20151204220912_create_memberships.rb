class CreateMemberships < ActiveRecord::Migration
  def change
    create_table :memberships do |t|
      t.integer    :user_id
      t.integer    :repo_id
      t.timestamps null: false
    end
    
    create_table :owners do |t|
      t.integer  :github_id
      t.string   :name
      t.boolean  :organization
    end

    add_index :owners, :github_id, unique: true
    
    add_column :users, :token, :string
    add_column :users, :syncing, :boolean, default: false
    
    add_column :repos, :owner_id, :integer
    add_column :repos, :webhook_id, :string
    add_column :repos, :active, :boolean, default: false
    add_column :repos, :private, :boolean, default: false
    rename_column :repos, :path, :github_full_name
    
    add_index :memberships, [:user_id, :repo_id], unique: true
    add_index :repos, :github_id, unique: true
    add_index :repos, :github_full_name, unique: true
  end
end