SELECT
  users.id AS user_id,
  users.email,
  users.name,
  COUNT(DISTINCT orders.id) AS total_orders,
  SUM(orders.total_amount) AS lifetime_value,
  AVG(orders.total_amount) AS avg_order_value,
  COUNT(DISTINCT user_activities.id) AS total_activities,
  COUNT(DISTINCT CASE WHEN user_activities.activity_type = 'page_view' THEN user_activities.id END) AS page_views,
  COUNT(DISTINCT CASE WHEN user_activities.activity_type = 'add_to_cart' THEN user_activities.id END) AS add_to_cart_count,
  MAX(orders.order_date) AS last_order_date,
  MAX(user_activities.occurred_at) AS last_activity_date,
  DATE_PART('day', NOW() - MAX(user_activities.occurred_at)) AS days_since_last_activity
FROM users
LEFT JOIN orders ON users.id = orders.user_id
LEFT JOIN user_activities ON users.id = user_activities.user_id
GROUP BY users.id, users.email, users.name
ORDER BY lifetime_value DESC NULLS LAST
