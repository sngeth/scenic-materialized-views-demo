class CreateCategoryRevenues < ActiveRecord::Migration[8.0]
  def change
    create_view :category_revenues, materialized: true
    add_index :category_revenues, :category, unique: true
  end
end
