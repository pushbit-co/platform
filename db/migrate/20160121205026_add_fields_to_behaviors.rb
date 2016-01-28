class AddFieldsToBehaviors < ActiveRecord::Migration
  def change
    add_column :behaviors, :repository_type, :string
    add_column :behaviors, :repository_url, :string
    add_column :behaviors, :author_name, :string
    add_column :behaviors, :author_email, :string
    add_column :behaviors, :icon_url, :string
    add_column :behaviors, :checkout, :string
    add_column :behaviors, :keywords, :string, default: [], array: true
  end
end