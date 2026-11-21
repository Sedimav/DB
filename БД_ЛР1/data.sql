BEGIN;
SET LOCAL search_path = restaurant, public;
INSERT INTO customers(full_name, phone) VALUES
('Анна Иванова', '+79990000001'),
('Дмитрий Петров', '+79990000002'),
('Мария Соколова', '+79990000003'),
('Алексей Смирнов', '+79990000004');
INSERT INTO employees(full_name, personnel_number) VALUES
('Елена Орлова', 'EMP-001'),
('Игорь Волков', 'EMP-002'),
('Ольга Морозова', 'EMP-003');
INSERT INTO dining_tables(table_number, seats) VALUES
(1,2), (2,4), (3,6), (4,2), (5,4);
INSERT INTO menu_categories(name) VALUES
('Салаты'), ('Супы'), ('Горячие блюда'), ('Десерты'), ('Напитки');
INSERT INTO menu_items(category_id, name, current_price, is_available)
SELECT c.category_id, v.name, v.price, v.available
FROM (VALUES
('Салаты','Цезарь с курицей',450.00,true),
('Салаты','Греческий салат',390.00,true),
('Супы','Борщ',320.00,true),
('Супы','Грибной крем-суп',350.00,true),
('Горячие блюда','Паста карбонара',560.00,true),
('Горячие блюда','Курица с рисом',520.00,true),
('Горячие блюда','Стейк',1100.00,false),
('Десерты','Чизкейк',330.00,true),
('Напитки','Чай',150.00,true),
('Напитки','Американо',190.00,true)
) AS v(category,name,price,available)
JOIN menu_categories c ON c.name = v.category;

INSERT INTO orders(order_number, table_id, employee_id, customer_id,
                   opened_at, closed_at, status)
SELECT v.number, t.table_id, e.employee_id, c.customer_id,
       v.opened::timestamptz, v.closed::timestamptz, v.status
FROM (VALUES
('R-001',1,'EMP-001','+79990000001','2026-10-14 12:00:00+03','2026-10-14 13:00:00+03','closed'),
('R-002',2,'EMP-002','+79990000002','2026-10-14 13:10:00+03','2026-10-14 14:00:00+03','closed'),
('R-003',3,'EMP-001','+79990000003','2026-10-14 15:00:00+03',NULL,'open'),
('R-004',4,'EMP-003',NULL,'2026-10-14 15:30:00+03',NULL,'open'),
('R-005',5,'EMP-002','+79990000004','2026-10-14 16:00:00+03','2026-10-14 16:05:00+03','cancelled'),
('R-006',1,'EMP-003',NULL,'2026-10-14 17:00:00+03','2026-10-14 17:45:00+03','closed')
) AS v(number,table_number,employee_number,phone,opened,closed,status)
JOIN dining_tables t ON t.table_number = v.table_number
JOIN employees e ON e.personnel_number = v.employee_number
LEFT JOIN customers c ON c.phone = v.phone;

INSERT INTO order_items(order_id, line_number, menu_item_id, quantity, unit_price)
SELECT o.order_id, v.line, m.menu_item_id, v.qty, v.price
FROM (VALUES
('R-001',1,'Цезарь с курицей',1,430.00),
('R-001',2,'Борщ',1,300.00),
('R-001',3,'Чай',2,150.00),
('R-002',1,'Паста карбонара',2,560.00),
('R-002',2,'Американо',2,190.00),
('R-003',1,'Греческий салат',2,390.00),
('R-003',2,'Курица с рисом',2,520.00),
('R-003',3,'Чай',2,150.00),
('R-004',1,'Грибной крем-суп',1,350.00),
('R-004',2,'Чизкейк',1,330.00),
('R-005',1,'Паста карбонара',1,560.00),
('R-006',1,'Чизкейк',2,330.00),
('R-006',2,'Американо',2,190.00)
) AS v(number,line,item,qty,price)
JOIN orders o ON o.order_number = v.number
JOIN menu_items m ON m.name = v.item;
COMMIT;
