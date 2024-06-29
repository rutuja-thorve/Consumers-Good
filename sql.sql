-- Request 1 =  Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

SELECT market, region
FROM dim_customer
WHERE customer = "Atliq Exclusive" AND region = "APAC"
GROUP BY market
ORDER BY market;


-- Request 2 - What is the percentage of unique product increase in 2021 vs. 2020? 

SELECT X.year_2020 AS unique_product_2020, Y.year_2021 AS unique_products_2021, ROUND((year_2021-year_2020)*100/year_2020, 2) AS percentage_chg
FROM
     (
      (SELECT COUNT(DISTINCT(product_code)) AS year_2020 FROM fact_sales_monthly
      WHERE fiscal_year = 2020) X,
      (SELECT COUNT(DISTINCT(product_code)) AS year_2021 FROM fact_sales_monthly
      WHERE fiscal_year = 2021) Y 
	 );
     

--  Request 3 - Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. 
     
	SELECT segment, count(distinct(product_code)) as Product_count FROM dim_product
	GROUP BY segment
	ORDER BY Product_count DESC;
    

-- Request 4 - Which segment had the most increase in unique products in 2021 vs 2020?
    
WITH cte1 AS (
SELECT p.segment, COUNT(DISTINCT(s.product_code)) AS a 
FROM dim_product p 
JOIN fact_sales_monthly s 
ON p.product_code = s.product_code
WHERE s.fiscal_year = 2020
GROUP BY p.segment),
cte2 AS (
SELECT p.segment, COUNT(DISTINCT(s.product_code)) AS b
FROM dim_product p JOIN fact_sales_monthly s 
ON p.product_code = s.product_code
WHERE s.fiscal_year = 2021
GROUP BY p.segment)
SELECT cte1.segment, cte1.a AS product_count_2020, cte2.b AS product_count_2021, b-a AS difference
FROM cte2 JOIN cte1
WHERE cte1.segment = cte2.segment
ORDER BY difference DESC;
    

-- Request 5 - Get the products that have the highest and lowest manufacturing costs.

SELECT p.product_code, p.product, m.manufacturing_cost FROM dim_product p JOIN fact_manufacturing_cost m
ON p.product_code = m.product_code
WHERE manufacturing_cost IN 
(SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost
UNION
SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost)
ORDER BY manufacturing_cost DESC;


/* Request 6 Generate a report which contains the top 5 customers who received 
an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market*/

WITH A1 AS (
SELECT customer_code, AVG(pre_invoice_discount_pct) AS B
FROM fact_pre_invoice_deductions 
WHERE fiscal_year = 2021
GROUP BY customer_code),
B1 AS (
SELECT customer_code, customer FROM dim_customer
WHERE market = "india")

SELECT b.customer_code, b.customer, ROUND(a.B, 4) AS avg_discount_pct FROM A1 a JOIN B1 b
ON a.customer_code = b.customer_code
ORDER BY avg_discount_pct DESC
LIMIT 5;


/* Request 7 - Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” 
for each month. This analysis helps to get an idea of low and high-performing months 
and take strategic decisions.*/

SELECT CONCAT(MONTHNAME(s.date), ' [', YEAR(s.date), ']') AS 'Month', s.fiscal_year, 
ROUND(SUM(s.sold_quantity*g.gross_price),2) AS gross_sales_amount
FROM dim_customer c JOIN fact_sales_monthly s
ON c.customer_code = s.customer_code
JOIN fact_gross_price g
ON s.product_code = g.product_code 
WHERE c.customer = "Atliq Exclusive"
GROUP BY Month, s.fiscal_year
ORDER BY S.fiscal_year;


-- request 8 - In which quarter of 2020, got the maximum total_sold_quantity?
 SELECT 
CASE
    WHEN date BETWEEN '2019-09-01' AND '2019-11-01' then CONCAT('[',"Q1",'] ',MONTHNAME(date))  
    WHEN date BETWEEN '2019-12-01' AND '2020-02-01' then CONCAT('[',"Q2",'] ',MONTHNAME(date))
    WHEN date BETWEEN '2020-03-01' AND '2020-05-01' then CONCAT('[',"Q3",'] ',MONTHNAME(date))
    WHEN date BETWEEN '2020-06-01' AND '2020-08-01' then CONCAT('[',"Q4",'] ',MONTHNAME(date))
    END AS Quarters,
    SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarters;
 
 

/* Request 9 -Which channel helped to bring more gross sales in the fiscal year 2021
    and the percentage of contribution? */
    
WITH A1 AS
(
SELECT C.channel,
       ROUND(SUM(G.gross_price*S.sold_quantity/1000000), 2) AS Gross_sales_mln
FROM fact_sales_monthly S JOIN dim_customer C ON S.customer_code = C.customer_code
						   JOIN fact_gross_price G ON S.product_code = G.product_code
WHERE S.fiscal_year = 2021
GROUP BY C.channel
)
SELECT channel, CONCAT(Gross_sales_mln,' M') AS Gross_sales_mln , Gross_sales_mln*100/SUM(Gross_sales_mln) OVER() AS percentage
FROM A1
ORDER BY percentage DESC;
    
    

/* Request 10 Get the Top 3 products in each division that have a high
total_sold_quantity in the fiscal_year 2021? */
    
WITH A1 AS 
(
SELECT P.division, S.product_code, P.product, SUM(S.sold_quantity) AS Total_sold_quantity
FROM dim_product P JOIN fact_sales_monthly S
ON P.product_code = S.product_code
WHERE S.fiscal_year = 2021 
GROUP BY  S.product_code, division, P.product
),
B1 AS 
(
SELECT division, product_code, product, Total_sold_quantity,
        RANK() OVER(PARTITION BY division ORDER BY Total_sold_quantity DESC) AS Rank_NO
FROM A1
)
 SELECT A1.division, A1.product_code, A1.product, B1.Total_sold_quantity, B1.Rank_NO
 FROM A1 JOIN B1
 ON A1.product_code = B1.product_code
WHERE B1.Rank_NO IN (1,2,3);