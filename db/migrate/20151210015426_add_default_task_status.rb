class AddDefaultTaskStatus < ActiveRecord::Migration
  def change
    change_column :tasks, :status, :string, :default => :pending
  end
end
