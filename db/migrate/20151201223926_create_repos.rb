class CreateRepos < ActiveRecord::Migration
  def change
    create_table :repos do |t|
      t.integer    :github_id
      t.string     :name
      t.string     :owner
      t.string     :path
      t.string     :bots, array:true, default:[]
      t.timestamps null: false
    end
  end
end
