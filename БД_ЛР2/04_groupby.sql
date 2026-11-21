-- 1. Количество заказов каждого сотрудника по статусам, включая сотрудников без заказов.
SELECT e.personnel_number, e.full_name,
       COUNT(o.order_id) AS all_orders,
       COUNT(CASE WHEN o.status = 'closed' THEN 1 END) AS closed_orders,
       COUNT(CASE WHEN o.status = 'open' THEN 1 END) AS open_orders,
       COUNT(CASE WHEN o.status = 'cancelled' THEN 1 END) AS cancelled_orders
FROM restaurant.employees e
LEFT JOIN restaurant.orders o ON o.employee_id = e.employee_id
GROUP BY e.employee_id, e.personnel_number, e.full_name
ORDER BY all_orders DESC, e.personnel_number;

-- 2. Продажи категорий с выручкой от 2000. Чеки считаются без повторов; AVG(unit_price) — средняя цена по позициям.
SELECT c.name AS category, COUNT(DISTINCT o.order_id) AS closed_orders,
       SUM(oi.quantity) AS units_sold,
       SUM(oi.quantity * oi.unit_price) AS revenue,
       round(AVG(oi.unit_price), 2) AS avg_line_unit_price,
       MIN(oi.unit_price) AS min_unit_price, MAX(oi.unit_price) AS max_unit_price
FROM restaurant.menu_categories c
JOIN restaurant.menu_items m ON m.category_id = c.category_id
JOIN restaurant.order_items oi ON oi.menu_item_id = m.menu_item_id
JOIN restaurant.orders o ON o.order_id = oi.order_id
WHERE o.status = 'closed'
GROUP BY c.category_id, c.name
HAVING SUM(oi.quantity * oi.unit_price) >= 2000
ORDER BY revenue DESC, c.name;

-- 3. Статистика по месяцу открытия: сначала суммы отдельных заказов, затем средний чек и месячные итоги.
SELECT date_trunc('month', x.opened_at AT TIME ZONE 'Europe/Moscow')::date AS month,
       COUNT(*) AS closed_orders, SUM(x.order_total) AS revenue,
       round(AVG(x.order_total), 2) AS average_check,
       MIN(x.order_total) AS min_check, MAX(x.order_total) AS max_check
FROM (
    SELECT o.order_id, o.opened_at,
           COALESCE(SUM(oi.quantity * oi.unit_price), 0) AS order_total
    FROM restaurant.orders o
    LEFT JOIN restaurant.order_items oi ON oi.order_id = o.order_id
    WHERE o.status = 'closed'
    GROUP BY o.order_id, o.opened_at
) x
GROUP BY month
ORDER BY month;
