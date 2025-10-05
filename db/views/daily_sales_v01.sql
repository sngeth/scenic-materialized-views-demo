SELECT
  DATE(orders.order_date) AS sale_date,
  COUNT(DISTINCT orders.id) AS total_orders,
  COUNT(DISTINCT orders.user_id) AS unique_customers,
  SUM(orders.total_amount) AS total_revenue,
  AVG(orders.total_amount) AS average_order_value,
  SUM(CASE WHEN orders.status = 'completed' THEN 1 ELSE 0 END) AS completed_orders,
  SUM(CASE WHEN orders.status = 'cancelled' THEN 1 ELSE 0 END) AS cancelled_orders,
  SUM(CASE WHEN orders.status = 'refunded' THEN 1 ELSE 0 END) AS refunded_orders
FROM orders
GROUP BY DATE(orders.order_date)
ORDER BY sale_date DESC
