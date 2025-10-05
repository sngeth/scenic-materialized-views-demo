namespace :sql do
  desc "Deep dive into SQL query analysis"
  task analysis: :environment do
    puts "=" * 80
    puts "DEEP DIVE: SQL QUERY ANALYSIS"
    puts "=" * 80

    # Enable detailed query logging
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.logger.level = Logger::DEBUG

    puts "\n" + "=" * 80
    puts "1. QUERY EXECUTION PLANS (with buffers & costs)"
    puts "=" * 80

    # Daily Sales - Raw Query with EXPLAIN (ANALYZE, BUFFERS)
    puts "\n📊 Daily Sales - Raw Aggregation Query"
    puts "-" * 80

    raw_query = <<~SQL
      EXPLAIN (ANALYZE, BUFFERS, VERBOSE, COSTS, TIMING)
      SELECT
        DATE(orders.order_date) AS sale_date,
        COUNT(DISTINCT orders.id) AS total_orders,
        COUNT(DISTINCT orders.user_id) AS unique_customers,
        SUM(orders.total_amount) AS total_revenue,
        AVG(orders.total_amount) AS average_order_value
      FROM orders
      GROUP BY DATE(orders.order_date)
      ORDER BY sale_date DESC
      LIMIT 30
    SQL

    result = ActiveRecord::Base.connection.execute(raw_query)
    result.each { |row| puts row['QUERY PLAN'] }

    # Daily Sales - Materialized View
    puts "\n📊 Daily Sales - Materialized View Query"
    puts "-" * 80

    view_query = <<~SQL
      EXPLAIN (ANALYZE, BUFFERS, VERBOSE, COSTS, TIMING)
      SELECT * FROM daily_sales
      ORDER BY sale_date DESC
      LIMIT 30
    SQL

    result = ActiveRecord::Base.connection.execute(view_query)
    result.each { |row| puts row['QUERY PLAN'] }

    puts "\n" + "=" * 80
    puts "2. USER ENGAGEMENT - Complex Multi-Table Join Analysis"
    puts "=" * 80

    puts "\n📊 Raw Multi-Table Aggregation (Users + Orders + Activities)"
    puts "-" * 80

    complex_raw = <<~SQL
      EXPLAIN (ANALYZE, BUFFERS, VERBOSE, COSTS, TIMING)
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

    result = ActiveRecord::Base.connection.execute(complex_raw)
    result.each { |row| puts row['QUERY PLAN'] }

    puts "\n📊 User Engagement - Materialized View"
    puts "-" * 80

    engagement_view = <<~SQL
      EXPLAIN (ANALYZE, BUFFERS, VERBOSE, COSTS, TIMING)
      SELECT * FROM user_engagements
      ORDER BY lifetime_value DESC
      LIMIT 100
    SQL

    result = ActiveRecord::Base.connection.execute(engagement_view)
    result.each { |row| puts row['QUERY PLAN'] }

    puts "\n" + "=" * 80
    puts "3. INDEX USAGE ANALYSIS"
    puts "=" * 80

    # Check what indexes exist
    indexes_query = <<~SQL
      SELECT
        schemaname,
        tablename,
        indexname,
        indexdef
      FROM pg_indexes
      WHERE tablename IN ('orders', 'users', 'products', 'order_items', 'user_activities',
                          'daily_sales', 'top_products', 'user_engagements', 'category_revenues')
      ORDER BY tablename, indexname;
    SQL

    result = ActiveRecord::Base.connection.execute(indexes_query)
    result.each do |row|
      puts "\n#{row['tablename']}.#{row['indexname']}:"
      puts "  #{row['indexdef']}"
    end

    puts "\n" + "=" * 80
    puts "4. TABLE & VIEW STATISTICS"
    puts "=" * 80

    stats_query = <<~SQL
      SELECT
        schemaname,
        relname as table_name,
        n_live_tup as row_count,
        n_dead_tup as dead_rows,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||relname)) as total_size,
        pg_size_pretty(pg_relation_size(schemaname||'.'||relname)) as table_size,
        pg_size_pretty(pg_total_relation_size(schemaname||'.'||relname) - pg_relation_size(schemaname||'.'||relname)) as index_size,
        last_vacuum,
        last_autovacuum,
        last_analyze
      FROM pg_stat_user_tables
      WHERE relname IN ('orders', 'users', 'products', 'order_items', 'user_activities',
                        'daily_sales', 'top_products', 'user_engagements', 'category_revenues')
      ORDER BY n_live_tup DESC;
    SQL

    puts "\n%-25s %12s %12s %12s %12s" % ["Table", "Rows", "Dead Rows", "Table Size", "Index Size"]
    puts "-" * 80

    result = ActiveRecord::Base.connection.execute(stats_query)
    result.each do |row|
      puts "%-25s %12s %12s %12s %12s" % [
        row['table_name'],
        row['row_count'].to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse,
        row['dead_rows'].to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse,
        row['table_size'],
        row['index_size']
      ]
    end

    puts "\n" + "=" * 80
    puts "5. CACHE HIT RATIO (should be >99% for good performance)"
    puts "=" * 80

    cache_query = <<~SQL
      SELECT
        schemaname,
        relname,
        heap_blks_read as disk_reads,
        heap_blks_hit as cache_hits,
        CASE
          WHEN (heap_blks_hit + heap_blks_read) = 0 THEN 0
          ELSE ROUND(100.0 * heap_blks_hit / (heap_blks_hit + heap_blks_read), 2)
        END as cache_hit_ratio
      FROM pg_statio_user_tables
      WHERE relname IN ('orders', 'users', 'products', 'order_items', 'user_activities',
                        'daily_sales', 'top_products', 'user_engagements', 'category_revenues')
      ORDER BY heap_blks_read DESC;
    SQL

    puts "\n%-25s %15s %15s %15s" % ["Table", "Disk Reads", "Cache Hits", "Hit Ratio %"]
    puts "-" * 80

    result = ActiveRecord::Base.connection.execute(cache_query)
    result.each do |row|
      ratio = row['cache_hit_ratio'].to_f
      status = ratio > 99 ? "✅" : ratio > 95 ? "⚠️" : "❌"

      puts "%-25s %15s %15s %14.2f%% %s" % [
        row['relname'],
        row['disk_reads'].to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse,
        row['cache_hits'].to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse,
        ratio,
        status
      ]
    end

    puts "\n" + "=" * 80
    puts "6. QUERY COST BREAKDOWN"
    puts "=" * 80

    # Get cost estimates without running queries
    puts "\nEstimated Query Costs (lower is better):"
    puts "-" * 80

    queries = {
      "Daily Sales (Raw)" => "SELECT DATE(orders.order_date), COUNT(*) FROM orders GROUP BY DATE(orders.order_date)",
      "Daily Sales (View)" => "SELECT * FROM daily_sales LIMIT 30",
      "Top Products (Raw)" => "SELECT products.id, SUM(order_items.subtotal) FROM products LEFT JOIN order_items ON products.id = order_items.product_id GROUP BY products.id",
      "Top Products (View)" => "SELECT * FROM top_products LIMIT 100",
      "User Engagement (Raw)" => "SELECT users.id, COUNT(orders.id), COUNT(user_activities.id) FROM users LEFT JOIN orders ON users.id = orders.user_id LEFT JOIN user_activities ON users.id = user_activities.user_id GROUP BY users.id",
      "User Engagement (View)" => "SELECT * FROM user_engagements LIMIT 100"
    }

    queries.each do |name, sql|
      result = ActiveRecord::Base.connection.execute("EXPLAIN #{sql}")
      first_line = result.first['QUERY PLAN']

      # Extract cost from EXPLAIN output
      if first_line =~ /cost=([\d.]+)\.\.([\d.]+)/
        start_cost = $1
        total_cost = $2
        puts "%-30s Cost: %10s..%10s" % [name, start_cost, total_cost]
      end
    end

    puts "\n" + "=" * 80
    puts "7. SEQUENTIAL SCANS vs INDEX SCANS"
    puts "=" * 80

    scan_query = <<~SQL
      SELECT
        schemaname,
        relname,
        seq_scan as sequential_scans,
        seq_tup_read as seq_rows_read,
        idx_scan as index_scans,
        idx_tup_fetch as idx_rows_fetched,
        CASE
          WHEN seq_scan = 0 THEN 'Index Only'
          WHEN idx_scan = 0 THEN 'Sequential Only'
          ELSE ROUND(100.0 * idx_scan / (seq_scan + idx_scan), 2)::text || '% Index'
        END as scan_pattern
      FROM pg_stat_user_tables
      WHERE relname IN ('orders', 'users', 'products', 'order_items', 'user_activities',
                        'daily_sales', 'top_products', 'user_engagements', 'category_revenues')
      ORDER BY seq_scan DESC;
    SQL

    puts "\n%-25s %15s %18s %15s" % ["Table", "Seq Scans", "Index Scans", "Pattern"]
    puts "-" * 80

    result = ActiveRecord::Base.connection.execute(scan_query)
    result.each do |row|
      puts "%-25s %15s %18s %15s" % [
        row['relname'],
        row['sequential_scans'].to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse,
        row['index_scans']&.to_s&.reverse&.gsub(/(\d{3})(?=\d)/, '\\1,')&.reverse || '0',
        row['scan_pattern']
      ]
    end

    puts "\n" + "=" * 80
    puts "ANALYSIS COMPLETE"
    puts "=" * 80

    puts "\nKey Insights:"
    puts "  • Raw queries use Sequential Scans (slow, reads entire table)"
    puts "  • Materialized views use Index Scans (fast, reads specific rows)"
    puts "  • Buffer stats show cache vs disk reads"
    puts "  • Cost estimates predict query performance before execution"
    puts "=" * 80
  end

  desc "Enable pg_stat_statements for ongoing query monitoring"
  task enable_pg_stat_statements: :environment do
    puts "Checking pg_stat_statements extension..."

    result = ActiveRecord::Base.connection.execute(<<~SQL)
      SELECT * FROM pg_available_extensions WHERE name = 'pg_stat_statements';
    SQL

    if result.count > 0
      ActiveRecord::Base.connection.execute("CREATE EXTENSION IF NOT EXISTS pg_stat_statements;")
      puts "✅ pg_stat_statements enabled!"

      puts "\nTop 10 slowest queries:"
      puts "-" * 80

      slow_queries = ActiveRecord::Base.connection.execute(<<~SQL)
        SELECT
          LEFT(query, 60) as query_snippet,
          calls,
          ROUND(mean_exec_time::numeric, 2) as avg_time_ms,
          ROUND(total_exec_time::numeric, 2) as total_time_ms
        FROM pg_stat_statements
        WHERE query NOT LIKE '%pg_stat_statements%'
        ORDER BY mean_exec_time DESC
        LIMIT 10;
      SQL

      slow_queries.each do |row|
        puts "#{row['query_snippet']}"
        puts "  Calls: #{row['calls']}, Avg: #{row['avg_time_ms']}ms, Total: #{row['total_time_ms']}ms"
        puts
      end
    else
      puts "❌ pg_stat_statements not available"
      puts "Add to postgresql.conf:"
      puts "  shared_preload_libraries = 'pg_stat_statements'"
    end
  rescue => e
    puts "Error: #{e.message}"
  end

  desc "Analyze a specific query with detailed breakdown"
  task :analyze_query, [:query] => :environment do |t, args|
    query = args[:query] || ENV['QUERY']

    if query.nil?
      puts "Usage: rails sql:analyze_query QUERY='SELECT * FROM orders'"
      exit 1
    end

    puts "=" * 80
    puts "ANALYZING QUERY"
    puts "=" * 80
    puts query
    puts "=" * 80

    result = ActiveRecord::Base.connection.execute("EXPLAIN (ANALYZE, BUFFERS, VERBOSE, COSTS) #{query}")
    result.each { |row| puts row['QUERY PLAN'] }
  end
end
