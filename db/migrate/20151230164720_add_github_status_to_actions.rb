class AddGithubStatusToActions < ActiveRecord::Migration
  def change
    add_column :actions, :github_status, :string
    add_column :users, :onboarding_skipped, :boolean, default: false
  end
end
