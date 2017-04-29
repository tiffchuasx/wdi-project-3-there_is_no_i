class CreateReviews < ActiveRecord::Migration[5.0]
  def change
    create_table :reviews do |t|
      t.integer :restaurant_id
      t.integer :rating
      t.text :comments

      t.timestamps
    end
  end
end
