class CreateDailySales < ActiveRecord::Migration[8.0]
  def change
    create_view :daily_sales, materialized: true
    add_index :daily_sales, :sale_date, unique: true
  end
end
