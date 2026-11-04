DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS returns;

CREATE TABLE sales (
    invoice      VARCHAR(20),
    stock_code   VARCHAR(20),
    description  TEXT,
    quantity     INTEGER,
    invoice_date TIMESTAMP,
    unit_price   NUMERIC(10,2),
    customer_id  INTEGER,        -- can be empty (NULL)
    country      VARCHAR(50),
    revenue      NUMERIC(12,2)
);

CREATE TABLE returns (LIKE sales);   -- same columns as sales