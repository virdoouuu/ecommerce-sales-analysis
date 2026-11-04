-- Q1a. Monthly net revenue (gross sales + returns)
WITH monthly_sales AS (
    SELECT DATE_TRUNC('month', invoice_date)::date AS month,
           SUM(revenue) AS gross_sales
    FROM sales
    GROUP BY 1
),
monthly_returns AS (
    SELECT DATE_TRUNC('month', invoice_date)::date AS month,
           SUM(revenue) AS returns
    FROM returns
    GROUP BY 1
)
SELECT s.month,
       ROUND(s.gross_sales) AS gross_sales,
       ROUND(COALESCE(r.returns, 0)) AS returns,
       ROUND(s.gross_sales + COALESCE(r.returns, 0)) AS net_revenue
FROM monthly_sales s
LEFT JOIN monthly_returns r USING (month)
ORDER BY s.month;
-- MySQL: use DATE_FORMAT(invoice_date, '%Y-%m-01') instead of DATE_TRUNC

-- Q1b. Year 1 vs year 2 (full 12 months each)
WITH all_lines AS (
    SELECT invoice_date, revenue FROM sales
    UNION ALL
    SELECT invoice_date, revenue FROM returns   -- returns are negative, so this nets them
)
SELECT CASE WHEN invoice_date < '2010-12-01' THEN 'Year 1 (Dec 2009 - Nov 2010)'
            ELSE 'Year 2 (Dec 2010 - Nov 2011)' END AS period,
       ROUND(SUM(revenue)) AS net_revenue
FROM all_lines
WHERE invoice_date < '2011-12-01'
GROUP BY 1
ORDER BY 1;

-- Q2. Top 20 products and their share of total sales
WITH product_revenue AS (
    SELECT stock_code, MAX(description) AS description, SUM(revenue) AS revenue
    FROM sales
    GROUP BY stock_code
)
SELECT description,
       ROUND(revenue) AS revenue,
       ROUND(100 * revenue / SUM(revenue) OVER (), 2) AS pct_of_total,
       ROUND(100 * SUM(revenue) OVER (ORDER BY revenue DESC) / SUM(revenue) OVER (), 1) AS cumulative_pct
FROM product_revenue
ORDER BY revenue DESC
LIMIT 20;

-- Q3. Repeat rate (customers with an ID only)
WITH orders_per_customer AS (
    SELECT customer_id, COUNT(DISTINCT invoice) AS orders
    FROM sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
)
SELECT COUNT(*) AS customers,
       SUM(CASE WHEN orders >= 2 THEN 1 ELSE 0 END) AS repeat_customers,
       ROUND(100.0 * SUM(CASE WHEN orders >= 2 THEN 1 ELSE 0 END) / COUNT(*), 1) AS repeat_rate_pct
FROM orders_per_customer;

-- Q4. Top 10 countries
SELECT country,
       ROUND(SUM(revenue)) AS revenue,
       COUNT(DISTINCT customer_id) AS customers,
       COUNT(DISTINCT invoice) AS orders,
       ROUND(SUM(revenue) / COUNT(DISTINCT invoice)) AS aov,
       ROUND(100 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1) AS pct_of_total
FROM sales
GROUP BY country
ORDER BY revenue DESC
LIMIT 10;

-- Q5. Revenue from new vs returning customers
WITH first_order AS (
    SELECT customer_id, MIN(invoice_date) AS first_date
    FROM sales
    WHERE customer_id IS NOT NULL
    GROUP BY customer_id
),
tagged AS (
    SELECT s.revenue,
           CASE WHEN DATE_TRUNC('month', s.invoice_date) = DATE_TRUNC('month', f.first_date)
                THEN 'new' ELSE 'returning' END AS customer_type
    FROM sales s
    JOIN first_order f USING (customer_id)
)
SELECT customer_type,
       ROUND(SUM(revenue)) AS revenue,
       ROUND(100 * SUM(revenue) / SUM(SUM(revenue)) OVER (), 1) AS pct
FROM tagged
GROUP BY customer_type;
-- Note: data starts Dec 2009, so some "new" customers in Dec 2009 may be older customers.