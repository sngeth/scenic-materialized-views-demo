class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.string :name
      t.text :description
      t.decimal :price
      t.string :sku
      t.string :category

      t.timestamps
    end

    add_index :products, :sku, unique: true
    add_index :products, :category
    add_index :products, :price
  end
end
