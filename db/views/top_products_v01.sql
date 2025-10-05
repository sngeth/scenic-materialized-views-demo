SELECT
  products.id AS product_id,
  products.name AS product_name,
  products.category,
  products.price,
  COUNT(DISTINCT order_items.order_id) AS times_ordered,
  SUM(order_items.quantity) AS total_quantity_sold,
  SUM(order_items.subtotal) AS total_revenue,
  AVG(order_items.quantity) AS avg_quantity_per_order,
  (SUM(order_items.subtotal) / NULLIF(SUM(order_items.quantity), 0)) AS avg_revenue_per_unit
FROM products
LEFT JOIN order_items ON products.id = order_items.product_id
GROUP BY products.id, products.name, products.category, products.price
ORDER BY total_revenue DESC NULLS LAST
