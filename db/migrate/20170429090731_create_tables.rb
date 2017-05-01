class CreateTables < ActiveRecord::Migration[5.0]
  def change
    create_table :tables do |t|
      t.integer :restaurant_id
      t.string :name
      t.integer :capacity_total
      t.integer :capacity_current

      t.timestamps
    end
  end
end
