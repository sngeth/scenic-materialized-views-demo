# Materialized Views Performance Case Study

A production-ready Rails application demonstrating the power of PostgreSQL materialized views for dashboard reporting with millions of records using the [Scenic](https://github.com/scenic-views/scenic) gem.

## 📊 Overview

This project showcases how materialized views can dramatically improve query performance for analytics dashboards that handle millions of records. It includes:

- **E-commerce analytics schema** with Users, Products, Orders, and User Activities
- **4 materialized views** for different reporting needs
- **Comprehensive benchmarking tools** to measure performance gains
- **Production-ready seed data generator** capable of creating millions of records
- **Automated view refresh** using background jobs
- **Beautiful dashboard UI** to visualize metrics

## 🚀 Quick Start

### Prerequisites

- Ruby 3.2+
- PostgreSQL 14+
- Rails 8.0+

### Installation

```bash
# Clone the repository
git clone <your-repo-url>
cd scenic-materialized-views-demo

# Install dependencies
bundle install

# Setup database
rails db:create db:migrate

# Seed database (default: 100K users, 10K products, 1M orders, 5M activities)
rails db:seed

# Or customize the data volume
USERS_COUNT=50000 PRODUCTS_COUNT=5000 rails db:seed

# Refresh materialized views
rails benchmark:refresh

# Start the server
rails server
```

Visit `http://localhost:3000` to see the dashboard!

## 📈 Performance Benchmarks

### Running Benchmarks

```bash
# Run comprehensive performance comparison
rails benchmark:compare

# Show query execution plans
rails benchmark:explain

# Refresh all materialized views
rails benchmark:refresh
```

### Expected Results

With 100,000 users, 1,000,000 orders, and 5,000,000 user activities:

| Query Type | Raw Query | Materialized View | Improvement |
|------------|-----------|-------------------|-------------|
| Daily Sales Summary | ~500ms | ~5ms | **100x faster** |
| Top Products | ~800ms | ~3ms | **266x faster** |
| User Engagement | ~1200ms | ~8ms | **150x faster** |
| Category Revenue | ~600ms | ~2ms | **300x faster** |

*Note: Actual performance will vary based on hardware and data volume*

## 🏗️ Architecture

### Database Schema

```
┌─────────┐     ┌──────────┐     ┌─────────────┐
│  Users  │────<│  Orders  │>────│ Order Items │
└─────────┘     └──────────┘     └─────────────┘
     │                                    │
     │                                    │
     v                                    v
┌──────────────┐               ┌──────────────┐
│User Activities│               │  Products    │
└──────────────┘               └──────────────┘
```

### Materialized Views

#### 1. Daily Sales Summary (`daily_sales`)
Aggregates daily order metrics including revenue, order count, unique customers, and status breakdown.

```sql
-- Refresh time: ~2-5s for 1M orders
SELECT refresh FROM scenic.refresh_materialized_view('daily_sales');
```

#### 2. Top Products (`top_products`)
Analyzes product performance with total revenue, quantity sold, and average metrics.

```sql
-- Refresh time: ~3-8s for 10K products with 3M order items
SELECT refresh FROM scenic.refresh_materialized_view('top_products');
```

#### 3. User Engagement (`user_engagements`)
Tracks user behavior, lifetime value, activity counts, and engagement patterns.

```sql
-- Refresh time: ~5-15s for 100K users with 5M activities
SELECT refresh FROM scenic.refresh_materialized_view('user_engagements');
```

#### 4. Category Revenue (`category_revenues`)
Summarizes revenue and performance metrics by product category.

```sql
-- Refresh time: ~2-5s for 8 categories
SELECT refresh FROM scenic.refresh_materialized_view('category_revenues');
```

## 🔄 View Refresh Strategy

### Automatic Refresh (Production)

Materialized views are automatically refreshed every hour using Solid Queue:

```yaml
# config/recurring.yml
production:
  refresh_materialized_views:
    class: RefreshMaterializedViewsJob
    queue: default
    schedule: every hour
```

### Manual Refresh

```ruby
# Refresh all views
DailySale.refresh
TopProduct.refresh
UserEngagement.refresh
CategoryRevenue.refresh

# Or use rake task
rails benchmark:refresh
```

### Refresh Strategies

**Choose based on your needs:**

1. **Hourly** (Default) - Good for most dashboards
2. **Daily** - For less time-sensitive reports
3. **On-demand** - Trigger manually after data changes
4. **Concurrent** - Use `concurrently: true` for zero-downtime refreshes (requires unique indexes)

## 📊 Data Generation

The seed file uses efficient batch inserts to generate production-like data:

```ruby
# Default configuration
USERS_COUNT=100_000          # 100K users
PRODUCTS_COUNT=10_000        # 10K products
ORDERS_PER_USER=10          # 1M orders total
ACTIVITIES_PER_USER=50      # 5M activities total

# Customize for testing
USERS_COUNT=1000 rails db:seed                    # Small dataset
USERS_COUNT=500000 rails db:seed                  # Large dataset
USERS_COUNT=10000 ORDERS_PER_USER=100 rails db:seed  # Many orders
```

## 🎯 Best Practices

### When to Use Materialized Views

✅ **Good Use Cases:**
- Dashboard reporting with acceptable data staleness
- Complex aggregations across multiple tables
- Queries that take >500ms with regular indexes
- Read-heavy workloads (99% reads, 1% writes)
- Historical/analytical queries

❌ **Not Recommended:**
- Real-time data requirements
- Write-heavy workloads
- Simple queries (already fast with indexes)
- Frequently changing data (refresh overhead)

### Performance Tips

1. **Add indexes** to materialized views on commonly filtered columns
2. **Schedule refreshes** during low-traffic periods
3. **Use CONCURRENTLY** for large views to avoid locking
4. **Monitor refresh times** and adjust strategy accordingly
5. **Consider partial refreshes** for incremental updates
6. **Use regular views** for simple joins without aggregations

### Monitoring Refresh Performance

```ruby
# Track refresh times
start = Time.now
DailySale.refresh
duration = Time.now - start
Rails.logger.info "DailySale refreshed in #{duration}s"
```

## 🚀 Deployment

### Render

The project includes Render configuration (`render.yaml`):

```bash
# Deploy to Render
git push render main

# Set environment variables in Render dashboard:
RAILS_MASTER_KEY=<your-master-key>
```

### Alternative Platforms

The app works on any platform supporting Rails + PostgreSQL:
- Heroku
- Railway
- Fly.io
- AWS/GCP/Azure

## 🔍 Querying Views in Rails

```ruby
# Use like regular Active Record models
DailySale.order(sale_date: :desc).limit(30)
TopProduct.where("total_revenue > ?", 10000)
UserEngagement.where("lifetime_value > ?", 1000).order(lifetime_value: :desc)

# Views are read-only
sale = DailySale.first
sale.readonly? # => true
```

## 📚 Resources

- [Scenic Gem Documentation](https://github.com/scenic-views/scenic)
- [PostgreSQL Materialized Views](https://www.postgresql.org/docs/current/sql-creatematerializedview.html)
- [Rails Performance Guide](https://guides.rubyonrails.org/performance_testing.html)

## 🧪 Testing

```bash
# Run tests
rails test

# Run system tests
rails test:system
```

## 📝 Key Learnings

### Performance Gains
- **100-300x faster** queries for complex aggregations
- **Consistent query times** regardless of data volume
- **Reduced database load** for repeated queries

### Trade-offs
- **Data staleness**: Views show cached data between refreshes
- **Storage overhead**: Views duplicate data
- **Refresh time**: Proportional to data volume
- **Maintenance**: Need to manage refresh schedules

### When Materialized Views Shine
- Dashboards with millions of records
- Complex multi-table aggregations
- Queries running multiple times per second
- Acceptable 5-60 minute data staleness

## 🤝 Contributing

Contributions welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is available as open source under the terms of the MIT License.

## 🙋‍♂️ Questions?

Open an issue or reach out to discuss materialized views, performance optimization, or Rails best practices!

---

**Built with ❤️ using Rails 8, PostgreSQL, and the Scenic gem**
