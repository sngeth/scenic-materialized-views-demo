SELECT
  products.category,
  COUNT(DISTINCT products.id) AS product_count,
  COUNT(DISTINCT order_items.order_id) AS total_orders,
  SUM(order_items.quantity) AS total_units_sold,
  SUM(order_items.subtotal) AS total_revenue,
  AVG(order_items.subtotal) AS avg_revenue_per_order,
  MIN(products.price) AS min_product_price,
  MAX(products.price) AS max_product_price,
  AVG(products.price) AS avg_product_price
FROM products
LEFT JOIN order_items ON products.id = order_items.product_id
GROUP BY products.category
ORDER BY total_revenue DESC NULLS LAST
