class RenameColumn < ActiveRecord::Migration
  def change
  	rename_column :favorites, :stopId, :stop_id 
  end
end
