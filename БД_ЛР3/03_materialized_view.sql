BEGIN;

-- 3. Сводка продаж по дням и категориям сохраняет готовые итоги для быстрого чтения.
CREATE MATERIALIZED VIEW IF NOT EXISTS restaurant.lr3_daily_category_sales AS
SELECT (o.closed_at AT TIME ZONE 'Europe/Moscow')::date AS sales_date,
       c.category_id, c.name AS category_name,
       COUNT(DISTINCT o.order_id) AS checks,
       SUM(oi.quantity) AS portions,
       SUM(oi.quantity * oi.unit_price) AS revenue
FROM restaurant.orders AS o
JOIN restaurant.order_items AS oi ON oi.order_id = o.order_id
JOIN restaurant.menu_items AS m ON m.menu_item_id = oi.menu_item_id
JOIN restaurant.menu_categories AS c ON c.category_id = m.category_id
WHERE o.status = 'closed'
GROUP BY sales_date, c.category_id, c.name
WITH NO DATA;

-- 4. Для анализа продаж в смену допустима задержка до часа.
-- Обновлять в начале и конце смены, каждый час и сразу после исправления выручки закрытого заказа.
REFRESH MATERIALIZED VIEW restaurant.lr3_daily_category_sales;

SELECT sales_date, category_name, checks, portions, revenue
FROM restaurant.lr3_daily_category_sales
ORDER BY sales_date DESC, category_name;

COMMIT;
