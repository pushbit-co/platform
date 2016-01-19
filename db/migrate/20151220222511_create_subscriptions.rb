class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.integer :user_id
      t.integer :repo_id
      t.string :stripe_subscription_id
      t.decimal :price

      t.timestamps null: false
    end

    add_column :users, :stripe_customer_id, :string
    add_index :subscriptions, :user_id
    add_index :subscriptions, :repo_id
  end
end