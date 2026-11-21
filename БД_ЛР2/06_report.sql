-- 1. Календарь: три месяца независимо от наличия продаж.
WITH months AS (
    SELECT month
    FROM (VALUES (DATE '2026-08-01'), (DATE '2026-09-01'),
                 (DATE '2026-10-01')) AS v(month)
),
-- 2. Позиции закрытых заказов по месяцу закрытия; выручка позиции = количество * цена продажи.
sale_lines AS (
    SELECT date_trunc('month', o.closed_at AT TIME ZONE 'Europe/Moscow')::date AS month,
           m.category_id, o.order_id, oi.quantity,
           oi.quantity * oi.unit_price AS line_revenue
    FROM restaurant.orders o
    JOIN restaurant.order_items oi ON oi.order_id = o.order_id
    JOIN restaurant.menu_items m ON m.menu_item_id = oi.menu_item_id
    WHERE o.status = 'closed'
      AND o.closed_at >= TIMESTAMPTZ '2026-08-01 00:00:00+03'
      AND o.closed_at < TIMESTAMPTZ '2026-11-01 00:00:00+03'
),
-- 3. Чеки, порции и выручка по месяцу и категории. Один заказ считается один раз внутри категории.
category_month AS (
    SELECT month, category_id, COUNT(DISTINCT order_id) AS checks,
           SUM(quantity) AS units_sold, SUM(line_revenue) AS revenue
    FROM sale_lines
    GROUP BY month, category_id
)
-- 4. Все 18 сочетаний месяц-категория; LEFT JOIN сохраняет отсутствие продаж, COALESCE выводит нули.
SELECT mon.month, c.name AS category,
       COALESCE(cm.checks, 0) AS checks,
       COALESCE(cm.units_sold, 0) AS units_sold,
       COALESCE(cm.revenue, 0) AS revenue
FROM months mon
CROSS JOIN restaurant.menu_categories c
LEFT JOIN category_month cm
    ON cm.month = mon.month AND cm.category_id = c.category_id
ORDER BY mon.month, revenue DESC, c.name;
