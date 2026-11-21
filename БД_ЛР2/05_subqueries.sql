-- 1. Блюда дороже средней текущей цены своей категории. Подзапрос связан с внешней категорией.
SELECT c.name AS category, m.name AS menu_item, m.current_price
FROM restaurant.menu_items m
JOIN restaurant.menu_categories c ON c.category_id = m.category_id
WHERE m.current_price > (
    SELECT AVG(m2.current_price)
    FROM restaurant.menu_items m2
    WHERE m2.category_id = m.category_id
)
ORDER BY c.name, m.current_price DESC, m.name;

-- 2. Клиенты, у которых есть закрытый заказ, открытый в сентябре. EXISTS проверяет наличие хотя бы одной строки.
SELECT c.customer_id, c.full_name, c.phone
FROM restaurant.customers c
WHERE EXISTS (
    SELECT 1
    FROM restaurant.orders o
    WHERE o.customer_id = c.customer_id AND o.status = 'closed'
      AND o.opened_at >= TIMESTAMPTZ '2026-09-01 00:00:00+03'
      AND o.opened_at < TIMESTAMPTZ '2026-10-01 00:00:00+03'
)
ORDER BY c.customer_id;

-- 3. Клиенты без закрытых заказов. Открытые и отменённые заказы у них могут быть.
SELECT c.customer_id, c.full_name, c.phone
FROM restaurant.customers c
WHERE NOT EXISTS (
    SELECT 1
    FROM restaurant.orders o
    WHERE o.customer_id = c.customer_id AND o.status = 'closed'
)
ORDER BY c.customer_id;

-- 4. Выручка закрытых заказов каждого клиента. При отсутствии продаж COALESCE возвращает 0.
SELECT c.customer_id, c.full_name,
       COALESCE((
           SELECT SUM(oi.quantity * oi.unit_price)
           FROM restaurant.orders o
           JOIN restaurant.order_items oi ON oi.order_id = o.order_id
           WHERE o.customer_id = c.customer_id AND o.status = 'closed'
       ), 0) AS closed_orders_revenue
FROM restaurant.customers c
ORDER BY closed_orders_revenue DESC, c.customer_id;
