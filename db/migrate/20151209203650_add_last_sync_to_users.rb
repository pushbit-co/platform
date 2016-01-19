class AddLastSyncToUsers < ActiveRecord::Migration
  def change
    add_column :users, :last_synchronized_at, :datetime
  end
end
