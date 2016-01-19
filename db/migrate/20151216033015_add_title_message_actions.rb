class AddTitleMessageActions < ActiveRecord::Migration
  def change
    add_column :actions, :title, :string
    add_column :actions, :body, :text
  end
end
