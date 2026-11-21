-- Повтор телефона
INSERT INTO restaurant.customers (full_name, phone)
VALUES ('Повторный телефон', '+79990000001');

-- Отсутствует обязательное имя
INSERT INTO restaurant.customers (full_name, phone)
VALUES (NULL, '+79990000099');

-- Несуществующая категория
INSERT INTO restaurant.menu_items (category_id, name, current_price)
VALUES (-1, 'Тестовое блюдо', 100.00);

-- Отрицательная цена
UPDATE restaurant.menu_items
SET current_price = -1
WHERE name = 'Борщ';

-- Нулевое количество
UPDATE restaurant.order_items
SET quantity = 0
WHERE order_id = (
    SELECT order_id FROM restaurant.orders WHERE order_number = 'R-001'
) AND line_number = 1;

-- Повтор названия в категории
INSERT INTO restaurant.menu_items (category_id, name, current_price)
SELECT category_id, name, current_price
FROM restaurant.menu_items
WHERE name = 'Борщ';

-- Повтор номера строки в заказе
INSERT INTO restaurant.order_items
    (order_id, line_number, menu_item_id, quantity, unit_price)
SELECT order_id, line_number, menu_item_id, quantity, unit_price
FROM restaurant.order_items
WHERE order_id = (
    SELECT order_id FROM restaurant.orders WHERE order_number = 'R-001'
) AND line_number = 1;

-- Закрытие раньше открытия
UPDATE restaurant.orders
SET closed_at = opened_at - INTERVAL '1 hour'
WHERE order_number = 'R-001';
