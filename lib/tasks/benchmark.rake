require 'benchmark/ips'

namespace :benchmark do
  desc "Compare performance of raw queries vs materialized views"
  task compare: :environment do
    puts "=" * 80
    puts "MATERIALIZED VIEW PERFORMANCE BENCHMARK"
    puts "=" * 80
    puts "\nDatabase Statistics:"
    puts "  Users: #{User.count.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
    puts "  Products: #{Product.count.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
    puts "  Orders: #{Order.count.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
    puts "  Order Items: #{OrderItem.count.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
    puts "  User Activities: #{UserActivity.count.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
    puts "\n" + "=" * 80

    # Refresh all materialized views first
    puts "\nRefreshing materialized views..."
    start_time = Time.now
    DailySale.refresh
    TopProduct.refresh
    UserEngagement.refresh
    CategoryRevenue.refresh
    refresh_time = Time.now - start_time
    puts "✓ All views refreshed in #{refresh_time.round(2)}s"

    puts "\n" + "=" * 80
    puts "BENCHMARK 1: Daily Sales Summary"
    puts "=" * 80

    Benchmark.ips do |x|
      x.config(time: 5, warmup: 2)

      x.report("Raw Query") do
        ActiveRecord::Base.connection.execute(<<~SQL).to_a
          SELECT
            DATE(orders.order_date) AS sale_date,
            COUNT(DISTINCT orders.id) AS total_orders,
            COUNT(DISTINCT orders.user_id) AS unique_customers,
            SUM(orders.total_amount) AS total_revenue,
            AVG(orders.total_amount) AS average_order_value,
            SUM(CASE WHEN orders.status = 'completed' THEN 1 ELSE 0 END) AS completed_orders
          FROM orders
          GROUP BY DATE(orders.order_date)
          ORDER BY sale_date DESC
          LIMIT 30
        SQL
      end

      x.report("Materialized View") do
        DailySale.order(sale_date: :desc).limit(30).to_a
      end

      x.compare!
    end

    puts "\n" + "=" * 80
    puts "BENCHMARK 2: Top Products by Revenue"
    puts "=" * 80

    Benchmark.ips do |x|
      x.config(time: 5, warmup: 2)

      x.report("Raw Query") do
        ActiveRecord::Base.connection.execute(<<~SQL).to_a
          SELECT
            products.id AS product_id,
            products.name AS product_name,
            products.category,
            SUM(order_items.subtotal) AS total_revenue,
            SUM(order_items.quantity) AS total_quantity_sold
          FROM products
          LEFT JOIN order_items ON products.id = order_items.product_id
          GROUP BY products.id, products.name, products.category
          ORDER BY total_revenue DESC NULLS LAST
          LIMIT 100
        SQL
      end

      x.report("Materialized View") do
        TopProduct.order(total_revenue: :desc).limit(100).to_a
      end

      x.compare!
    end

    puts "\n" + "=" * 80
    puts "BENCHMARK 3: User Engagement Metrics"
    puts "=" * 80

    Benchmark.ips do |x|
      x.config(time: 5, warmup: 2)

      x.report("Raw Query") do
        ActiveRecord::Base.connection.execute(<<~SQL).to_a
          SELECT
            users.id AS user_id,
            users.email,
            COUNT(DISTINCT orders.id) AS total_orders,
            SUM(orders.total_amount) AS lifetime_value,
            COUNT(DISTINCT user_activities.id) AS total_activities
          FROM users
          LEFT JOIN orders ON users.id = orders.user_id
          LEFT JOIN user_activities ON users.id = user_activities.user_id
          GROUP BY users.id, users.email
          ORDER BY lifetime_value DESC NULLS LAST
          LIMIT 100
        SQL
      end

      x.report("Materialized View") do
        UserEngagement.order(lifetime_value: :desc).limit(100).to_a
      end

      x.compare!
    end

    puts "\n" + "=" * 80
    puts "BENCHMARK 4: Category Revenue Analysis"
    puts "=" * 80

    Benchmark.ips do |x|
      x.config(time: 5, warmup: 2)

      x.report("Raw Query") do
        ActiveRecord::Base.connection.execute(<<~SQL).to_a
          SELECT
            products.category,
            COUNT(DISTINCT products.id) AS product_count,
            SUM(order_items.subtotal) AS total_revenue,
            SUM(order_items.quantity) AS total_units_sold
          FROM products
          LEFT JOIN order_items ON products.id = order_items.product_id
          GROUP BY products.category
          ORDER BY total_revenue DESC NULLS LAST
        SQL
      end

      x.report("Materialized View") do
        CategoryRevenue.order(total_revenue: :desc).to_a
      end

      x.compare!
    end

    puts "\n" + "=" * 80
    puts "BENCHMARK COMPLETE"
    puts "=" * 80
    puts "\nKey Findings:"
    puts "  - Materialized views provide significant performance improvements"
    puts "  - Views must be refreshed periodically to stay current"
    puts "  - Trade-off: Query speed vs. data freshness"
    puts "  - Ideal for reporting dashboards with acceptable staleness"
    puts "=" * 80
  end

  desc "Refresh all materialized views"
  task refresh: :environment do
    puts "Refreshing all materialized views..."

    start = Time.now
    DailySale.refresh
    puts "✓ DailySale refreshed (#{(Time.now - start).round(2)}s)"

    start = Time.now
    TopProduct.refresh
    puts "✓ TopProduct refreshed (#{(Time.now - start).round(2)}s)"

    start = Time.now
    UserEngagement.refresh
    puts "✓ UserEngagement refreshed (#{(Time.now - start).round(2)}s)"

    start = Time.now
    CategoryRevenue.refresh
    puts "✓ CategoryRevenue refreshed (#{(Time.now - start).round(2)}s)"

    puts "\n✅ All materialized views refreshed successfully!"
  end

  desc "Show EXPLAIN ANALYZE for queries"
  task explain: :environment do
    puts "=" * 80
    puts "QUERY EXECUTION PLANS"
    puts "=" * 80

    puts "\n1. Daily Sales - Raw Query:"
    puts "-" * 80
    result = ActiveRecord::Base.connection.execute(<<~SQL)
      EXPLAIN ANALYZE
      SELECT
        DATE(orders.order_date) AS sale_date,
        COUNT(DISTINCT orders.id) AS total_orders,
        SUM(orders.total_amount) AS total_revenue
      FROM orders
      GROUP BY DATE(orders.order_date)
      ORDER BY sale_date DESC
      LIMIT 30
    SQL
    result.each { |row| puts row['QUERY PLAN'] }

    puts "\n2. Daily Sales - Materialized View:"
    puts "-" * 80
    result = ActiveRecord::Base.connection.execute(<<~SQL)
      EXPLAIN ANALYZE
      SELECT * FROM daily_sales
      ORDER BY sale_date DESC
      LIMIT 30
    SQL
    result.each { |row| puts row['QUERY PLAN'] }
  end
end
