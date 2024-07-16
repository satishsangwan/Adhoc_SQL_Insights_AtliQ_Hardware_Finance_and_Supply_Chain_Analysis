# In this file SQL Queries for all 10 tasks are written##
# get_fiscal_year is a user defined function
# net_sales is not a physcial table in database it is a created database view

# Task 1. Croma India Product wise sales report for fiscal year 2021.#
SELECT 
    s.date,
    s.product_code,
    p.product,
    p.variant,
    s.sold_quantity,
    g.gross_price,
    ROUND(g.gross_price * s.sold_quantity, 2) AS gross_price_total
FROM
    fact_sales_monthly s
        JOIN
    dim_product p ON p.product_code = s.product_code
        JOIN
    fact_gross_price g ON g.product_code = s.product_code
        AND g.fiscal_year = GET_FISCAL_YEAR(s.date)
WHERE
    customer_code = 90002002  -- (Customer_Code for Croma India)
        AND GET_FISCAL_YEAR(date) = 2021
ORDER BY date ASC;
-- Get_Fiscal_Year is user defined function
-- 90002002 is customer_code for croma_india

# Task 2. Gross Monthly Total Sales report for Croma India Customer.#
SELECT 
    s.date,
    ROUND(SUM(g.gross_price * s.sold_quantity), 2) AS total_gross_sales
FROM
    fact_sales_monthly s
        JOIN
    fact_gross_price g ON g.product_code = s.product_code
        AND g.fiscal_year = GET_FISCAL_YEAR(s.date)
WHERE
    customer_code = 90002002
GROUP BY s.date
ORDER BY s.date;
-- 90002002 customer_code for Croma India
-- get_fiscal_year is user defined function

#Task 3. Generate a yearly gross sales report for Croma India#
SELECT 
    GET_FISCAL_YEAR(s.date) AS fiscal_year,
    ROUND(SUM(g.gross_price * s.sold_quantity), 2) AS yearly_sales
FROM
    fact_sales_monthly s
        JOIN
    fact_gross_price g ON g.product_code = s.product_code
        AND g.fiscal_year = GET_FISCAL_YEAR(s.date)
WHERE
    customer_code = 90002002
GROUP BY GET_FISCAL_YEAR(s.date)
ORDER BY fiscal_year;

#Task 4. Get top 5 market by net sales in fiscal year 2021#
SELECT 
    c.market,
    ROUND(SUM(net_sales) / 1000000, 2) AS net_sales_mln
FROM
    net_sales n
        JOIN
    dim_customer c ON c.customer_code = n.customer_code
WHERE
    fiscal_year = 2021
GROUP BY c.market
ORDER BY net_sales_mln DESC
LIMIT 5;
-- net_sales is not a physical table, it is a created database view

#Task 5. Get top 5 products by net sales in fiscal year 2021#
SELECT 
    p.product,
    ROUND(SUM(net_sales) / 1000000, 2) AS net_sales_mln
FROM
    net_sales n
        JOIN
    dim_product p ON p.product_code = n.product_code
WHERE
    fiscal_year = 2021
GROUP BY p.product
ORDER BY net_sales_mln DESC
LIMIT 5;

#Task 6. Get top 5 customers by net sales in fiscal year 2021#
SELECT 
    c.customer,
    ROUND(SUM(net_sales) / 1000000, 2) AS net_sales_mln
FROM
    net_sales n
        JOIN
    dim_customer c ON c.customer_code = n.customer_code
WHERE
    fiscal_year = 2021
GROUP BY c.customer
ORDER BY net_sales_mln DESC
LIMIT 5;

#Task 7. Net Sale Percentage Share Global #
WITH cte1 as (SELECT 
    c.customer,
    ROUND(SUM(net_sales) / 1000000, 2) AS net_sales_mln
FROM
    net_sales n
        JOIN
    dim_customer c ON c.customer_code = n.customer_code
WHERE
    fiscal_year = 2021
GROUP BY c.customer)
SELECT
	*,
    net_sales_mln*100/sum(net_sales_mln) OVER() as percentage_share
    FROM cte1
ORDER BY net_sales_mln DESC;

#Task. 8 Net Sales % Share by Region#
WITH cte1 as (SELECT 
    c.customer,
    c.region,
    ROUND(SUM(net_sales) / 1000000, 2) AS net_sales_mln
FROM
    net_sales n
        JOIN
    dim_customer c ON c.customer_code = n.customer_code
WHERE
    fiscal_year = 2021
GROUP BY c.customer,c.region)
SELECT
	*,
    net_sales_mln*100/sum(net_sales_mln) OVER (partition by region) as percentage_share
    FROM cte1
ORDER BY region,net_sales_mln DESC;

#Task. 10 Retrieve the top 2 markets in every region by their gross sales amount in FY=2021.#
WITH cte1 as (SELECT 
	c.market,
    c.region,
    round(sum(gross_price_total)/1000000,2) as gross_sales_mln
FROM gross_sales g
JOIN dim_customer c
ON c.customer_code = g.customer_code
WHERE fiscal_year = 2021 
GROUP BY c.region,c.market
ORDER BY gross_sales_mln DESC),
cte2 as (SELECT 
	*,
    dense_rank() over(partition by region order by gross_sales_mln desc) as drnk
FROM cte1)
SELECT 
	*
FROM cte2
WHERE drnk<=2;

#Task 10. Forecast Accuracy for all customers for a given fiscal year #
WITH forecast_err_table as (SELECT 
	s.customer_code,
    sum(s.sold_quantity) as total_sold_qty,
    sum(s.forecast_quantity) as total_forecast_qty,
    sum(forecast_quantity-sold_quantity) as net_error,
    sum((forecast_quantity-sold_quantity))*100/sum(forecast_quantity) as net_error_pct,
    sum(abs(forecast_quantity-sold_quantity)) as abs_error,
    sum(abs(forecast_quantity-sold_quantity))*100/sum(forecast_quantity) as abs_error_pct
FROM fact_act_est s
WHERE s.fiscal_year=2021
GROUP BY s.customer_code)
SELECT 
	e.customer_code,
    c.customer,
    c.market,
    e.total_sold_qty,
    e.total_forecast_qty,
    e.net_error,e.abs_error,
    if(abs_error_pct > 100,0,round((100-abs_error_pct),2)) as forecast_accuracy_pct
FROM forecast_err_table e
JOIN dim_customer c
using (customer_code)
ORDER BY forecast_accuracy_pct desc;
--------------------------------------------------------------
