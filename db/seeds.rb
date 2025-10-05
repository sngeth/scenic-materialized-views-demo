require 'faker'

puts "Cleaning database..."
UserActivity.delete_all
OrderItem.delete_all
Order.delete_all
Product.delete_all
User.delete_all

# Reset sequences
ActiveRecord::Base.connection.reset_pk_sequence!('users')
ActiveRecord::Base.connection.reset_pk_sequence!('products')
ActiveRecord::Base.connection.reset_pk_sequence!('orders')
ActiveRecord::Base.connection.reset_pk_sequence!('order_items')
ActiveRecord::Base.connection.reset_pk_sequence!('user_activities')

puts "Seeding database with production-level data..."

# Configuration - adjust these for different data volumes
USERS_COUNT = ENV.fetch('USERS_COUNT', 100_000).to_i
PRODUCTS_COUNT = ENV.fetch('PRODUCTS_COUNT', 10_000).to_i
ORDERS_PER_USER = ENV.fetch('ORDERS_PER_USER', 10).to_i
ACTIVITIES_PER_USER = ENV.fetch('ACTIVITIES_PER_USER', 50).to_i

BATCH_SIZE = 1000
CATEGORIES = ['Electronics', 'Clothing', 'Books', 'Home & Garden', 'Sports', 'Toys', 'Food', 'Beauty']
STATUSES = ['pending', 'processing', 'completed', 'cancelled', 'refunded']
ACTIVITY_TYPES = ['page_view', 'search', 'add_to_cart', 'remove_from_cart', 'wishlist_add', 'profile_update']

# Seed Products
puts "Creating #{PRODUCTS_COUNT} products..."
products_data = []
PRODUCTS_COUNT.times do |i|
  products_data << {
    name: Faker::Commerce.product_name,
    description: Faker::Lorem.paragraph(sentence_count: 3),
    price: Faker::Commerce.price(range: 10.0..1000.0),
    sku: "SKU-#{SecureRandom.hex(8)}",
    category: CATEGORIES.sample,
    created_at: Faker::Time.between(from: 2.years.ago, to: Time.now),
    updated_at: Time.now
  }

  if products_data.size >= BATCH_SIZE
    Product.insert_all(products_data)
    print "."
    products_data = []
  end
end
Product.insert_all(products_data) if products_data.any?
puts "\n✓ Created #{Product.count} products"

# Seed Users
puts "Creating #{USERS_COUNT} users..."
users_data = []
USERS_COUNT.times do |i|
  users_data << {
    email: "user#{i}@example.com",
    name: Faker::Name.name,
    created_at: Faker::Time.between(from: 2.years.ago, to: 1.month.ago),
    updated_at: Time.now
  }

  if users_data.size >= BATCH_SIZE
    User.insert_all(users_data)
    print "."
    users_data = []
  end
end
User.insert_all(users_data) if users_data.any?
puts "\n✓ Created #{User.count} users"

# Preload IDs for efficient reference
user_ids = User.pluck(:id)
product_ids = Product.pluck(:id)

# Seed Orders
puts "Creating orders (#{ORDERS_PER_USER} per user)..."
orders_data = []
order_counter = 0

user_ids.each_slice(100) do |user_batch|
  user_batch.each do |user_id|
    ORDERS_PER_USER.times do
      order_date = Faker::Time.between(from: 1.year.ago, to: Time.now)
      orders_data << {
        user_id: user_id,
        total_amount: 0, # Will be updated after order items
        status: STATUSES.sample,
        order_date: order_date,
        created_at: order_date,
        updated_at: order_date
      }

      if orders_data.size >= BATCH_SIZE
        Order.insert_all(orders_data)
        order_counter += orders_data.size
        print "\rCreated #{order_counter} orders..."
        orders_data = []
      end
    end
  end
end
Order.insert_all(orders_data) if orders_data.any?
order_counter += orders_data.size
puts "\n✓ Created #{Order.count} orders"

# Seed Order Items
puts "Creating order items (2-5 per order)..."
order_items_data = []
item_counter = 0

Order.find_in_batches(batch_size: 500) do |orders_batch|
  orders_batch.each do |order|
    items_count = rand(2..5)
    order_total = 0

    items_count.times do
      product_id = product_ids.sample
      product_price = Product.find(product_id).price
      quantity = rand(1..3)
      subtotal = product_price * quantity
      order_total += subtotal

      order_items_data << {
        order_id: order.id,
        product_id: product_id,
        quantity: quantity,
        unit_price: product_price,
        subtotal: subtotal,
        created_at: order.created_at,
        updated_at: order.created_at
      }

      if order_items_data.size >= BATCH_SIZE
        OrderItem.insert_all(order_items_data)
        item_counter += order_items_data.size
        print "\rCreated #{item_counter} order items..."
        order_items_data = []
      end
    end

    # Update order total
    order.update_column(:total_amount, order_total)
  end
end
OrderItem.insert_all(order_items_data) if order_items_data.any?
item_counter += order_items_data.size
puts "\n✓ Created #{OrderItem.count} order items"

# Seed User Activities
puts "Creating user activities (#{ACTIVITIES_PER_USER} per user)..."
activities_data = []
activity_counter = 0

user_ids.each_slice(100) do |user_batch|
  user_batch.each do |user_id|
    ACTIVITIES_PER_USER.times do
      occurred_at = Faker::Time.between(from: 6.months.ago, to: Time.now)
      activities_data << {
        user_id: user_id,
        activity_type: ACTIVITY_TYPES.sample,
        metadata: {
          page: Faker::Internet.url,
          device: ['mobile', 'desktop', 'tablet'].sample,
          browser: ['Chrome', 'Firefox', 'Safari', 'Edge'].sample,
          duration: rand(5..300)
        }.to_json,
        occurred_at: occurred_at,
        created_at: occurred_at,
        updated_at: occurred_at
      }

      if activities_data.size >= BATCH_SIZE
        UserActivity.insert_all(activities_data)
        activity_counter += activities_data.size
        print "\rCreated #{activity_counter} activities..."
        activities_data = []
      end
    end
  end
end
UserActivity.insert_all(activities_data) if activities_data.any?
activity_counter += activities_data.size
puts "\n✓ Created #{UserActivity.count} user activities"

puts "\n" + "="*50
puts "DATABASE SEEDING COMPLETE!"
puts "="*50
puts "Users: #{User.count.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
puts "Products: #{Product.count.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
puts "Orders: #{Order.count.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
puts "Order Items: #{OrderItem.count.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
puts "User Activities: #{UserActivity.count.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
puts "="*50
