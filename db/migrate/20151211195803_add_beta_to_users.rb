class AddBetaToUsers < ActiveRecord::Migration
  def up
    add_column :users, :beta, :boolean, default: false
    add_column :users, :token_scopes, :string
    Pushbit::User.where("token IS NOT NULL").update_all(token_scopes: 'user:email,repo')
  end
  
  def down
    remove_column :users, :beta
    remove_column :users, :token_scopes
  end
end
