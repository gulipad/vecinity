class ChangeColumn < ActiveRecord::Migration
  def change
  	change_column :favorites, :stop_id, :string
  end
end
