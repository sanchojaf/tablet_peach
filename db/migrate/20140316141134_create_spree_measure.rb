class CreateSpreeMeasure < ActiveRecord::Migration
  def change
    create_table :spree_measures do |t|
      t.integer  "measure_item_id"
      t.string :name
      t.integer :min
      t.integer :max
      t.integer :pos
      t.timestamps  
    end
  end
end
