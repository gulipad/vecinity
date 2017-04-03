class CreateFavorites < ActiveRecord::Migration
  def change
    create_table :favorites do |t|
      t.references :user, index: true	
      t.integer :stopId
      t.timestamps null: false
    end
  end
end
