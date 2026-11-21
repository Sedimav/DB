BEGIN;

-- 2.1. Журнал заказов.
CREATE OR REPLACE VIEW restaurant.lr3_order_register AS
SELECT o.order_id, o.order_number, t.table_number, t.seats,
       e.full_name AS employee_name,
       COALESCE(c.full_name, 'Гость без регистрации') AS customer_name,
       o.opened_at, o.closed_at, o.status
FROM restaurant.orders AS o
JOIN restaurant.dining_tables AS t ON t.table_id = o.table_id
JOIN restaurant.employees AS e ON e.employee_id = o.employee_id
LEFT JOIN restaurant.customers AS c ON c.customer_id = o.customer_id;

SELECT order_number, table_number, employee_name, customer_name, opened_at, closed_at, status
FROM restaurant.lr3_order_register
ORDER BY opened_at DESC, order_id DESC
LIMIT 10;

-- 2.2. Блюда с долей выручки категории от 25%.
SELECT category_name, menu_item, item_revenue, revenue_share_pct
FROM restaurant.lr3_menu_revenue_share
WHERE category_revenue > 0 AND item_revenue >= category_revenue * 0.25
ORDER BY category_name, revenue_share_pct DESC, menu_item;

-- 2.3. Редактирование столиков до четырёх мест.
CREATE OR REPLACE VIEW restaurant.lr3_small_tables AS
SELECT table_id, table_number, seats
FROM restaurant.dining_tables
WHERE seats <= 4
WITH CHECK OPTION;

SELECT table_number, seats
FROM restaurant.lr3_small_tables
ORDER BY table_number;

COMMIT;
