class CreateTopProducts < ActiveRecord::Migration[8.0]
  def change
    create_view :top_products, materialized: true
    add_index :top_products, :product_id, unique: true
  end
end
