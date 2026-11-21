BEGIN;

INSERT INTO restaurant.dining_tables (table_number, seats) VALUES (30100, 2), (30101, 4);

INSERT INTO restaurant.employees (full_name, personnel_number)
VALUES ('Сотрудник для проверки ЛР3', 'LR3-DEMO');

INSERT INTO restaurant.menu_categories (name)
VALUES ('ЛР3 — контрольные блюда'), ('ЛР3 — категория без продаж');

INSERT INTO restaurant.menu_items (category_id, name, current_price)
SELECT c.category_id, v.menu_item, v.price
FROM (VALUES
    ('ЛР3 — контрольные блюда', 'Оладьи', 150),
    ('ЛР3 — контрольные блюда', 'Тост', 120),
    ('ЛР3 — контрольные блюда', 'Омлет', 80),
    ('ЛР3 — контрольные блюда', 'Каша', 50),
    ('ЛР3 — категория без продаж', 'Пюре', 90)
) AS v(category_name, menu_item, price)
JOIN restaurant.menu_categories AS c ON c.name = v.category_name;

INSERT INTO restaurant.orders (order_number, table_id, employee_id, opened_at, closed_at, status)
SELECT v.order_number, t.table_id, e.employee_id, v.opened_at::timestamptz,
       v.closed_at::timestamptz, v.status
FROM (VALUES
    ('LR3-001', 30100, '2026-11-05 11:45+03', '2026-11-05 12:00+03', 'closed'),
    ('LR3-002', 30100, '2026-11-05 12:05+03', '2026-11-05 12:30+03', 'closed'),
    ('LR3-003', 30100, '2026-11-05 12:10+03', '2026-11-05 12:30+03', 'closed'),
    ('LR3-004', 30100, '2026-11-05 12:35+03', NULL,                   'open'),
    ('LR3-005', 30101, '2026-11-05 11:50+03', '2026-11-05 12:15+03', 'closed')
) AS v(order_number, table_number, opened_at, closed_at, status)
JOIN restaurant.dining_tables AS t ON t.table_number = v.table_number
JOIN restaurant.employees AS e ON e.personnel_number = 'LR3-DEMO'
ORDER BY v.order_number;

INSERT INTO restaurant.order_items (order_id, line_number, menu_item_id, quantity, unit_price)
SELECT o.order_id, v.line_number, m.menu_item_id, v.quantity, v.unit_price
FROM (VALUES
    ('LR3-001', 1, 'Оладьи', 2, 100),
    ('LR3-001', 2, 'Тост',   1, 120),
    ('LR3-002', 1, 'Оладьи', 1, 100),
    ('LR3-002', 2, 'Тост',   1, 120),
    ('LR3-003', 1, 'Омлет',  1, 80),
    ('LR3-004', 1, 'Каша',   5, 50),
    ('LR3-005', 1, 'Тост',   1, 120)
) AS v(order_number, line_number, menu_item, quantity, unit_price)
JOIN restaurant.orders AS o ON o.order_number = v.order_number
JOIN restaurant.menu_categories AS c ON c.name = 'ЛР3 — контрольные блюда'
JOIN restaurant.menu_items AS m ON m.category_id = c.category_id AND m.name = v.menu_item;

-- 1.1. Оладьи и тост делят 1-е место, омлет на 2-м; каша и пюре без места.
SELECT category_name, menu_item, portions, place_in_category
FROM restaurant.lr3_menu_ranking
WHERE category_name IN ('ЛР3 — контрольные блюда', 'ЛР3 — категория без продаж')
ORDER BY category_name, place_in_category NULLS LAST, menu_item;

-- 1.2. Интервалы: NULL, 30 и 0 минут для столика 30100; NULL для 30101.
SELECT table_number, order_number, previous_order_number, time_since_previous
FROM restaurant.lr3_table_order_gaps
WHERE table_number IN (30100, 30101)
ORDER BY table_number, closed_at, order_id;

-- 1.3. Итог категории 740; в категории без продаж доля NULL.
SELECT category_name, menu_item, item_revenue, category_revenue, revenue_share_pct
FROM restaurant.lr3_menu_revenue_share
WHERE category_name IN ('ЛР3 — контрольные блюда', 'ЛР3 — категория без продаж')
ORDER BY category_name, item_revenue DESC, menu_item;

-- 2.2. В выборке остаются тост и оладьи.
SELECT menu_item, revenue_share_pct
FROM restaurant.lr3_menu_revenue_share
WHERE category_name = 'ЛР3 — контрольные блюда'
  AND category_revenue > 0 AND item_revenue >= category_revenue * 0.25
ORDER BY revenue_share_pct DESC;

-- 2.3. Изменение с 2 до 4 мест проходит; до 6 мест отклоняется.
UPDATE restaurant.lr3_small_tables SET seats = 4 WHERE table_number = 30100;
SELECT table_number, seats
FROM restaurant.dining_tables
WHERE table_number = 30100;

DO $$
BEGIN
    UPDATE restaurant.lr3_small_tables SET seats = 6 WHERE table_number = 30100;
    RAISE EXCEPTION 'Проверка провалена: представление разрешило изменение до 6 мест';
EXCEPTION
    WHEN SQLSTATE '44000' THEN
        RAISE NOTICE 'Ожидаемый отказ CHECK OPTION (44000): %', SQLERRM;
END;
$$;

SELECT table_number, seats AS seats_after_rejected_update
FROM restaurant.lr3_small_tables
WHERE table_number = 30100;

-- 3–4. До закрытия заказа выручка в сводке 740.
REFRESH MATERIALIZED VIEW restaurant.lr3_daily_category_sales;

-- 2.1. Журнал сразу показывает смену статуса с open на closed.
SELECT order_number, customer_name, status, closed_at
FROM restaurant.lr3_order_register
WHERE order_number = 'LR3-004';

UPDATE restaurant.orders
SET status = 'closed', closed_at = TIMESTAMPTZ '2026-11-05 12:55+03'
WHERE order_number = 'LR3-004';

SELECT order_number, customer_name, status, closed_at
FROM restaurant.lr3_order_register
WHERE order_number = 'LR3-004';

-- До REFRESH: обычное представление 990, сводка 740.
SELECT live.category_revenue AS live_revenue,
       snapshot.checks, snapshot.portions, snapshot.revenue AS stored_revenue
FROM restaurant.lr3_daily_category_sales AS snapshot
JOIN restaurant.lr3_menu_revenue_share AS live ON live.category_id = snapshot.category_id
WHERE snapshot.sales_date = DATE '2026-11-05'
  AND snapshot.category_name = 'ЛР3 — контрольные блюда' AND live.menu_item = 'Каша';

REFRESH MATERIALIZED VIEW restaurant.lr3_daily_category_sales;

-- После REFRESH: 990 в обоих представлениях.
SELECT live.category_revenue AS live_revenue,
       snapshot.checks, snapshot.portions, snapshot.revenue AS stored_revenue
FROM restaurant.lr3_daily_category_sales AS snapshot
JOIN restaurant.lr3_menu_revenue_share AS live ON live.category_id = snapshot.category_id
WHERE snapshot.sales_date = DATE '2026-11-05'
  AND snapshot.category_name = 'ЛР3 — контрольные блюда' AND live.menu_item = 'Каша';

ROLLBACK;
