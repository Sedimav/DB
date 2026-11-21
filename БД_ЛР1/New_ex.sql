BEGIN;

SET LOCAL search_path = restaurant, public;

CREATE TABLE restaurants (
    restaurant_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(120) NOT NULL
);

INSERT INTO restaurants (name)
VALUES
    ('Первый ресторан'),
    ('Второй ресторан');

CREATE TABLE employee_restaurants (
    employee_id bigint REFERENCES employees (employee_id),
    restaurant_id bigint REFERENCES restaurants (restaurant_id),
    PRIMARY KEY (employee_id, restaurant_id)
);

INSERT INTO employee_restaurants (employee_id, restaurant_id)
SELECT employee_id, 1
FROM employees;

ALTER TABLE orders
    ADD COLUMN restaurant_id bigint NOT NULL DEFAULT 1,
    DROP CONSTRAINT fk_orders_employee,
    ADD CONSTRAINT fk_orders_employee_restaurant
        FOREIGN KEY (employee_id, restaurant_id)
        REFERENCES employee_restaurants (employee_id, restaurant_id)
        ON DELETE RESTRICT;

COMMIT;

SELECT
    o.order_number AS "Номер заказа",
    r.name AS "Ресторан"
FROM restaurant.orders o
JOIN restaurant.restaurants r
    ON r.restaurant_id = o.restaurant_id;

SELECT
    r.name AS "Ресторан",
    COUNT(er.employee_id) AS "Количество работников"
FROM restaurant.restaurants r
LEFT JOIN restaurant.employee_restaurants er
    ON er.restaurant_id = r.restaurant_id
GROUP BY r.restaurant_id, r.name;
