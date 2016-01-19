class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.integer    :github_id
      t.string     :email
      t.string     :login
      t.string     :name
      t.string     :company
      t.string     :gravitar_id
      t.timestamps null: false
    end
  end
end
