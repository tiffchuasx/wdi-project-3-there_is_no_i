class CreateReservations < ActiveRecord::Migration[5.0]
  def change
    create_table :reservations do |t|
      t.references :user, foreign_key: true
      t.string :user_name
      t.string :phone
      t.string :email
      t.integer :party_size
      t.integer :restaurant_id
      t.datetime :date_time
      t.references :restaurant, foreign_key: true
      t.boolean :is_queuing
      t.references :table, foreign_key: true

      t.timestamps
    end
  end
end