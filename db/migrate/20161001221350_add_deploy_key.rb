class AddDeployKey < ActiveRecord::Migration
  def change
    add_column :repos, :salt, :text
    add_column :repos, :deploy_private_key, :text
    add_column :repos, :webhook_key, :text
  end
end
