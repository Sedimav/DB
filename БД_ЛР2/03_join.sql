-- 1. Позиции открытых заказов. LEFT JOIN сохраняет заказы без зарегистрированного клиента.
SELECT o.order_number, t.table_number, e.full_name AS employee,
       COALESCE(c.full_name, 'Гость без регистрации') AS customer,
       o.opened_at AT TIME ZONE 'Europe/Moscow' AS opened_at_moscow,
       oi.line_number, m.name AS menu_item, oi.quantity, oi.unit_price,
       oi.quantity * oi.unit_price AS line_total
FROM restaurant.orders o
JOIN restaurant.dining_tables t ON t.table_id = o.table_id
JOIN restaurant.employees e ON e.employee_id = o.employee_id
LEFT JOIN restaurant.customers c ON c.customer_id = o.customer_id
JOIN restaurant.order_items oi ON oi.order_id = o.order_id
JOIN restaurant.menu_items m ON m.menu_item_id = oi.menu_item_id
WHERE o.status = 'open'
ORDER BY o.opened_at, o.order_number, oi.line_number;

-- 2. Блюда, которых нет в позициях заказов любого статуса. NULL справа означает отсутствие совпадений.
SELECT c.name AS category, m.name AS menu_item, m.current_price, m.is_available
FROM restaurant.menu_items m
JOIN restaurant.menu_categories c ON c.category_id = m.category_id
LEFT JOIN restaurant.order_items oi ON oi.menu_item_id = m.menu_item_id
WHERE oi.order_id IS NULL
ORDER BY c.name, m.name;

-- 3. Клиенты с доступными сейчас напитками в закрытых заказах, открытых в октябре. DISTINCT убирает повторы клиентов.
SELECT DISTINCT c.customer_id, c.full_name, c.phone
FROM restaurant.customers c
JOIN restaurant.orders o ON o.customer_id = c.customer_id
JOIN restaurant.order_items oi ON oi.order_id = o.order_id
JOIN restaurant.menu_items m ON m.menu_item_id = oi.menu_item_id
JOIN restaurant.menu_categories mc ON mc.category_id = m.category_id
WHERE o.status = 'closed'
  AND o.opened_at >= TIMESTAMPTZ '2026-10-01 00:00:00+03'
  AND o.opened_at < TIMESTAMPTZ '2026-11-01 00:00:00+03'
  AND mc.name = 'Напитки' AND m.is_available
ORDER BY c.customer_id;
