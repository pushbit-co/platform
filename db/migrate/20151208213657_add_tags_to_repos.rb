class AddTagsToRepos < ActiveRecord::Migration
  def change
    add_column :repos, :tags, :string, array: true, default: []
  end
end
