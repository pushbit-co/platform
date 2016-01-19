class CreateSequential < ActiveRecord::Migration
  def change
    create_table(:sequential) do |t|
      t.string  :model
      t.string  :column
      t.string  :scope
      t.string  :scope_value
      t.integer :value
      t.timestamps null:false
    end

    add_index :sequential, [:model, :column, :scope, :scope_value], unique: true
    add_column :tasks, :sequential_id, :integer
    
    Pushbit::Task.reset_column_information
    Pushbit::Task.find_each do |task|
      task.set_sequential_values
      task.save(validate: false)
    end
  end
end
