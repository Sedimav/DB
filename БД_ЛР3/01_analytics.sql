BEGIN;

-- 1.1. Рейтинг блюд по числу проданных порций внутри категории.
CREATE OR REPLACE VIEW restaurant.lr3_menu_ranking AS
WITH item_sales AS (
    SELECT oi.menu_item_id, SUM(oi.quantity) AS portions
    FROM restaurant.order_items AS oi
    JOIN restaurant.orders AS o ON o.order_id = oi.order_id
    WHERE o.status = 'closed'
    GROUP BY oi.menu_item_id
)
SELECT c.category_id, c.name AS category_name,
       m.menu_item_id, m.name AS menu_item,
       COALESCE(s.portions, 0) AS portions,
       CASE WHEN s.portions IS NOT NULL THEN
           DENSE_RANK() OVER (
               PARTITION BY c.category_id ORDER BY s.portions DESC NULLS LAST
           )
       END AS place_in_category
FROM restaurant.menu_items AS m
JOIN restaurant.menu_categories AS c ON c.category_id = m.category_id
LEFT JOIN item_sales AS s ON s.menu_item_id = m.menu_item_id;

SELECT category_name, menu_item, portions, place_in_category
FROM restaurant.lr3_menu_ranking
ORDER BY category_name, place_in_category NULLS LAST, menu_item;

-- 1.2. Интервалы между закрытиями заказов одного столика.
CREATE OR REPLACE VIEW restaurant.lr3_table_order_gaps AS
WITH closed_orders AS (
    SELECT o.order_id, o.order_number, o.table_id, o.closed_at,
           LAG(o.order_number) OVER table_timeline AS previous_order_number,
           LAG(o.closed_at) OVER table_timeline AS previous_closed_at
    FROM restaurant.orders AS o
    WHERE o.status = 'closed'
    WINDOW table_timeline AS (PARTITION BY o.table_id ORDER BY o.closed_at, o.order_id)
)
SELECT t.table_number, o.order_id, o.order_number, o.closed_at,
       o.previous_order_number, o.previous_closed_at,
       o.closed_at - o.previous_closed_at AS time_since_previous
FROM closed_orders AS o
JOIN restaurant.dining_tables AS t ON t.table_id = o.table_id;

SELECT table_number, order_number, closed_at,
       previous_order_number, previous_closed_at, time_since_previous
FROM restaurant.lr3_table_order_gaps
ORDER BY table_number, closed_at, order_id;

-- 1.3. Доля блюда в выручке категории.
CREATE OR REPLACE VIEW restaurant.lr3_menu_revenue_share AS
WITH item_sales AS (
    SELECT oi.menu_item_id, SUM(oi.quantity * oi.unit_price) AS revenue
    FROM restaurant.order_items AS oi
    JOIN restaurant.orders AS o ON o.order_id = oi.order_id
    WHERE o.status = 'closed'
    GROUP BY oi.menu_item_id
), category_totals AS (
    SELECT c.category_id, c.name AS category_name,
           m.menu_item_id, m.name AS menu_item,
           COALESCE(s.revenue, 0) AS item_revenue,
           SUM(COALESCE(s.revenue, 0)) OVER (PARTITION BY c.category_id) AS category_revenue
    FROM restaurant.menu_items AS m
    JOIN restaurant.menu_categories AS c ON c.category_id = m.category_id
    LEFT JOIN item_sales AS s ON s.menu_item_id = m.menu_item_id
)
SELECT category_id, category_name, menu_item_id, menu_item, item_revenue, category_revenue,
       ROUND(100 * item_revenue / NULLIF(category_revenue, 0), 2) AS revenue_share_pct
FROM category_totals;

SELECT category_name, menu_item, item_revenue, category_revenue, revenue_share_pct
FROM restaurant.lr3_menu_revenue_share
ORDER BY category_name, item_revenue DESC, menu_item;

COMMIT;