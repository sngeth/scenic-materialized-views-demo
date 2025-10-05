class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.decimal :total_amount
      t.string :status
      t.datetime :order_date

      t.timestamps
    end

    add_index :orders, :status
    add_index :orders, :order_date
    add_index :orders, [:user_id, :order_date]
  end
end
