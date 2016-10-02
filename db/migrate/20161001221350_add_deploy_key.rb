class AddDeployKey < ActiveRecord::Migration
  def change
    add_column :repos, :salt, :text
    add_column :repos, :ssh_key, :text
    add_column :repos, :deploy_key_id, :integer
    add_column :repos, :webhook_key, :text
  end
end
