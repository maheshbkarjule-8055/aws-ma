CREATE SCHEMA IF NOT EXISTS ma;

CREATE TABLE ma.customer_info (
    customer_id VARCHAR(50),
    customer_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    city VARCHAR(50),
    registration_date DATE
);

CREATE TABLE ma.orders (
    order_id VARCHAR(50),
    customer_id VARCHAR(50),
    order_date DATE,
    product_name VARCHAR(100),
    quantity INT,
    price DECIMAL(10,2)
);