# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_10_03_132726) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity"
    t.decimal "unit_price"
    t.decimal "subtotal"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.decimal "total_amount"
    t.string "status"
    t.datetime "order_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_date"], name: "index_orders_on_order_date"
    t.index ["status"], name: "index_orders_on_status"
    t.index ["user_id", "order_date"], name: "index_orders_on_user_id_and_order_date"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.decimal "price"
    t.string "sku"
    t.string "category"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_products_on_category"
    t.index ["price"], name: "index_products_on_price"
    t.index ["sku"], name: "index_products_on_sku", unique: true
  end

  create_table "user_activities", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "activity_type"
    t.jsonb "metadata"
    t.datetime "occurred_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_type"], name: "index_user_activities_on_activity_type"
    t.index ["occurred_at"], name: "index_user_activities_on_occurred_at"
    t.index ["user_id", "occurred_at"], name: "index_user_activities_on_user_id_and_occurred_at"
    t.index ["user_id"], name: "index_user_activities_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_users_on_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "orders", "users"
  add_foreign_key "user_activities", "users"

  create_view "category_revenues", materialized: true, sql_definition: <<-SQL
      SELECT products.category,
      count(DISTINCT products.id) AS product_count,
      count(DISTINCT order_items.order_id) AS total_orders,
      sum(order_items.quantity) AS total_units_sold,
      sum(order_items.subtotal) AS total_revenue,
      avg(order_items.subtotal) AS avg_revenue_per_order,
      min(products.price) AS min_product_price,
      max(products.price) AS max_product_price,
      avg(products.price) AS avg_product_price
     FROM (products
       LEFT JOIN order_items ON ((products.id = order_items.product_id)))
    GROUP BY products.category
    ORDER BY (sum(order_items.subtotal)) DESC NULLS LAST;
  SQL
  add_index "category_revenues", ["category"], name: "index_category_revenues_on_category", unique: true

  create_view "daily_sales", materialized: true, sql_definition: <<-SQL
      SELECT date(order_date) AS sale_date,
      count(DISTINCT id) AS total_orders,
      count(DISTINCT user_id) AS unique_customers,
      sum(total_amount) AS total_revenue,
      avg(total_amount) AS average_order_value,
      sum(
          CASE
              WHEN ((status)::text = 'completed'::text) THEN 1
              ELSE 0
          END) AS completed_orders,
      sum(
          CASE
              WHEN ((status)::text = 'cancelled'::text) THEN 1
              ELSE 0
          END) AS cancelled_orders,
      sum(
          CASE
              WHEN ((status)::text = 'refunded'::text) THEN 1
              ELSE 0
          END) AS refunded_orders
     FROM orders
    GROUP BY (date(order_date))
    ORDER BY (date(order_date)) DESC;
  SQL
  add_index "daily_sales", ["sale_date"], name: "index_daily_sales_on_sale_date", unique: true

  create_view "top_products", materialized: true, sql_definition: <<-SQL
      SELECT products.id AS product_id,
      products.name AS product_name,
      products.category,
      products.price,
      count(DISTINCT order_items.order_id) AS times_ordered,
      sum(order_items.quantity) AS total_quantity_sold,
      sum(order_items.subtotal) AS total_revenue,
      avg(order_items.quantity) AS avg_quantity_per_order,
      (sum(order_items.subtotal) / (NULLIF(sum(order_items.quantity), 0))::numeric) AS avg_revenue_per_unit
     FROM (products
       LEFT JOIN order_items ON ((products.id = order_items.product_id)))
    GROUP BY products.id, products.name, products.category, products.price
    ORDER BY (sum(order_items.subtotal)) DESC NULLS LAST;
  SQL
  add_index "top_products", ["product_id"], name: "index_top_products_on_product_id", unique: true

  create_view "user_engagements", materialized: true, sql_definition: <<-SQL
      SELECT users.id AS user_id,
      users.email,
      users.name,
      count(DISTINCT orders.id) AS total_orders,
      sum(orders.total_amount) AS lifetime_value,
      avg(orders.total_amount) AS avg_order_value,
      count(DISTINCT user_activities.id) AS total_activities,
      count(DISTINCT
          CASE
              WHEN ((user_activities.activity_type)::text = 'page_view'::text) THEN user_activities.id
              ELSE NULL::bigint
          END) AS page_views,
      count(DISTINCT
          CASE
              WHEN ((user_activities.activity_type)::text = 'add_to_cart'::text) THEN user_activities.id
              ELSE NULL::bigint
          END) AS add_to_cart_count,
      max(orders.order_date) AS last_order_date,
      max(user_activities.occurred_at) AS last_activity_date,
      date_part('day'::text, (now() - (max(user_activities.occurred_at))::timestamp with time zone)) AS days_since_last_activity
     FROM ((users
       LEFT JOIN orders ON ((users.id = orders.user_id)))
       LEFT JOIN user_activities ON ((users.id = user_activities.user_id)))
    GROUP BY users.id, users.email, users.name
    ORDER BY (sum(orders.total_amount)) DESC NULLS LAST;
  SQL
  add_index "user_engagements", ["user_id"], name: "index_user_engagements_on_user_id", unique: true

end
