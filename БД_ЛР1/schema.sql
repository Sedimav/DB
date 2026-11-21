BEGIN;
CREATE SCHEMA restaurant;
SET LOCAL search_path = restaurant, public;

CREATE TABLE customers (
    customer_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name varchar(120) NOT NULL,
    phone varchar(20) NOT NULL,
    CONSTRAINT uq_customers_phone UNIQUE (phone),
    CONSTRAINT ck_customers_name CHECK (btrim(full_name) <> ''),
    CONSTRAINT ck_customers_phone CHECK (phone ~ '^\+[0-9]{10,15}$')
);

CREATE TABLE employees (
    employee_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name varchar(120) NOT NULL,
    personnel_number varchar(20) NOT NULL,
    CONSTRAINT uq_employees_personnel UNIQUE (personnel_number),
    CONSTRAINT ck_employees_name CHECK (btrim(full_name) <> ''),
    CONSTRAINT ck_employees_personnel CHECK (btrim(personnel_number) <> '')
);

CREATE TABLE dining_tables (
    table_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_number smallint NOT NULL,
    seats smallint NOT NULL,
    CONSTRAINT uq_dining_tables_number UNIQUE (table_number),
    CONSTRAINT ck_dining_tables_number CHECK (table_number > 0),
    CONSTRAINT ck_dining_tables_seats CHECK (seats BETWEEN 1 AND 20)
);

CREATE TABLE menu_categories (
    category_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name varchar(80) NOT NULL,
    CONSTRAINT uq_menu_categories_name UNIQUE (name),
    CONSTRAINT ck_menu_categories_name CHECK (btrim(name) <> '')
);

CREATE TABLE menu_items (
    menu_item_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    category_id bigint NOT NULL,
    name varchar(120) NOT NULL,
    current_price numeric(10,2) NOT NULL,
    is_available boolean NOT NULL DEFAULT true,
    CONSTRAINT fk_menu_items_category FOREIGN KEY (category_id)
        REFERENCES menu_categories(category_id) ON DELETE RESTRICT,
    CONSTRAINT uq_menu_items_category_name UNIQUE (category_id, name),
    CONSTRAINT ck_menu_items_name CHECK (btrim(name) <> ''),
    CONSTRAINT ck_menu_items_price CHECK (current_price > 0)
);

CREATE TABLE orders (
    order_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_number varchar(30) NOT NULL,
    table_id bigint NOT NULL,
    employee_id bigint NOT NULL,
    customer_id bigint,
    opened_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_at timestamptz,
    status varchar(20) NOT NULL DEFAULT 'open',
    CONSTRAINT uq_orders_number UNIQUE (order_number),
    CONSTRAINT fk_orders_table FOREIGN KEY (table_id)
        REFERENCES dining_tables(table_id) ON DELETE RESTRICT,
    CONSTRAINT fk_orders_employee FOREIGN KEY (employee_id)
        REFERENCES employees(employee_id) ON DELETE RESTRICT,
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id) ON DELETE SET NULL,
    CONSTRAINT ck_orders_number CHECK (btrim(order_number) <> ''),
    CONSTRAINT ck_orders_status CHECK (status IN ('open', 'closed', 'cancelled')),
    CONSTRAINT ck_orders_dates CHECK (closed_at IS NULL OR closed_at >= opened_at),
    CONSTRAINT ck_orders_lifecycle CHECK (
        status NOT IN ('open', 'closed', 'cancelled')
        OR (status = 'open' AND closed_at IS NULL)
        OR (status IN ('closed', 'cancelled') AND closed_at IS NOT NULL)
    )
);

CREATE TABLE order_items (
    order_id bigint NOT NULL,
    line_number smallint NOT NULL,
    menu_item_id bigint NOT NULL,
    quantity smallint NOT NULL,
    unit_price numeric(10,2) NOT NULL,
    CONSTRAINT pk_order_items PRIMARY KEY (order_id, line_number),
    CONSTRAINT fk_order_items_order FOREIGN KEY (order_id)
        REFERENCES orders(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_items_menu_item FOREIGN KEY (menu_item_id)
        REFERENCES menu_items(menu_item_id) ON DELETE RESTRICT,
    CONSTRAINT ck_order_items_line CHECK (line_number > 0),
    CONSTRAINT ck_order_items_quantity CHECK (quantity BETWEEN 1 AND 100),
    CONSTRAINT ck_order_items_price CHECK (unit_price > 0)
);

CREATE INDEX ix_orders_table ON orders(table_id);
CREATE INDEX ix_orders_employee ON orders(employee_id);
CREATE INDEX ix_orders_customer ON orders(customer_id);
CREATE INDEX ix_order_items_menu_item ON order_items(menu_item_id);
COMMIT;
