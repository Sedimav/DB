BEGIN;

-- 1. Показываем исходный статус заказа и текущие цены напитков.
SELECT order_number, status, closed_at
FROM restaurant.orders WHERE order_number = 'R-003';

SELECT m.name, m.current_price
FROM restaurant.menu_items m
JOIN restaurant.menu_categories c ON c.category_id = m.category_id
WHERE c.name = 'Напитки' ORDER BY m.name;

-- 2. Создаём клиента, связанный заказ и позицию заказа.
INSERT INTO restaurant.customers (full_name, phone)
VALUES ('Демонстрационный клиент ЛР2', '+79990000999')
RETURNING customer_id, full_name, phone;

INSERT INTO restaurant.orders
    (order_number, table_id, employee_id, customer_id, opened_at, status)
SELECT 'DEMO-LR2', t.table_id, e.employee_id, c.customer_id,
       TIMESTAMPTZ '2026-10-22 12:00:00+03', 'open'
FROM restaurant.dining_tables t
CROSS JOIN restaurant.employees e
CROSS JOIN restaurant.customers c
WHERE t.table_number = 1 AND e.personnel_number = 'EMP-001'
  AND c.phone = '+79990000999'
RETURNING order_id, order_number, customer_id, status;

-- Сохраняем ID отдельно от orders: после удаления родителя ID останется доступным.
-- Временная таблица существует только в этой сессии и исчезнет при откате.
CREATE TEMP TABLE lr2_demo_order_id ON COMMIT DROP AS
SELECT order_id FROM restaurant.orders WHERE order_number = 'DEMO-LR2';

INSERT INTO restaurant.order_items
    (order_id, line_number, menu_item_id, quantity, unit_price)
SELECT o.order_id, 1, m.menu_item_id, 2, m.current_price
FROM restaurant.orders o
CROSS JOIN restaurant.menu_items m
JOIN restaurant.menu_categories c ON c.category_id = m.category_id
WHERE o.order_number = 'DEMO-LR2' AND c.name = 'Напитки' AND m.name = 'Чай'
RETURNING order_id, line_number, quantity, unit_price;

-- 3. Закрываем заказ: статус и дата изменяются вместе.
UPDATE restaurant.orders
SET status = 'closed', closed_at = TIMESTAMPTZ '2026-10-14 16:00:00+03'
WHERE order_number = 'R-003' AND status = 'open'
RETURNING order_number, status, opened_at, closed_at;

-- 4. Массово повышаем текущие цены доступных напитков на 5%.
UPDATE restaurant.menu_items m
SET current_price = round(m.current_price * 1.05, 2)
FROM restaurant.menu_categories c
WHERE c.category_id = m.category_id AND c.name = 'Напитки' AND m.is_available
RETURNING m.name, m.current_price;

-- 5. Перед удалением у демонстрационного заказа должна быть одна позиция.
SELECT COUNT(*) AS items_before_delete
FROM restaurant.order_items
WHERE order_id = (SELECT order_id FROM lr2_demo_order_id);

DELETE FROM restaurant.orders WHERE order_number = 'DEMO-LR2'
RETURNING order_id, order_number;

-- После удаления должно быть 0 позиций.
-- Проверяем напрямую по сохранённому ID, без JOIN с удалённым заказом.
SELECT COUNT(*) AS items_after_delete
FROM restaurant.order_items
WHERE order_id = (SELECT order_id FROM lr2_demo_order_id);

-- 6. Отменяем добавления, обновления и удаление; временная таблица тоже исчезает.
ROLLBACK;

-- 7. Проверяем восстановление: клиента нет, статус заказа и цены как до изменений.
SELECT COUNT(*) AS demo_customers_after_rollback
FROM restaurant.customers WHERE phone = '+79990000999';

SELECT order_number, status, closed_at
FROM restaurant.orders WHERE order_number = 'R-003';

SELECT m.name, m.current_price
FROM restaurant.menu_items m
JOIN restaurant.menu_categories c ON c.category_id = m.category_id
WHERE c.name = 'Напитки' ORDER BY m.name;
