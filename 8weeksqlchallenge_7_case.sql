/* -------------------------------------------------
   Case Study Questions A: High Level Sales Analysis
   -------------------------------------------------*/
-- 1. What was the total quantity sold for all products?
SELECT SUM(qty) AS total_quantity_sold
FROM sales;

-- 2. What is the total generated revenue for all products before discounts?
SELECT SUM(qty * price) AS total_revenue_before_discounts
FROM sales;

-- 3. What was the total discount amount for all products?
SELECT ROUND(SUM(qty * price * (discount / 100)), 2) AS total_discount_amount
FROM sales;

/* --------------------------------------------
   Case Study Questions B: Transaction Analysis
   --------------------------------------------*/
-- 1. How many unique transactions were there?
SELECT COUNT(DISTINCT txn_id) AS unique_txn
FROM sales;

-- 2. What is the average unique products purchased in each transaction?
SELECT ROUND(AVG(unique_products), 0) AS avg_unique_products
FROM (
	SELECT txn_id, SUM(prod_id) AS unique_products
    FROM sales
    GROUP BY txn_id
    ) AS unique_products;

-- 3. What are the 25th, 50th and 75th percentile values for the revenue per transaction?
SELECT DISTINCT(ROUND(revenue, 0)) AS revenue, revenue_percentile
FROM (
	SELECT txn_id, revenue, ROUND(PERCENT_RANK() OVER(ORDER BY revenue), 3) AS revenue_percentile
    FROM (
		SELECT txn_id, ROUND(SUM(qty * price * (1 - discount / 100)), 2) AS revenue
        FROM sales
        GROUP BY txn_id
        ) AS revenue
	) AS percentile
WHERE revenue_percentile IN (0.25, 0.5, 0.75);

-- 4. What is the average discount value per transaction?
SELECT ROUND(AVG(total_discount_amount), 2) AS avg_discount_value
FROM (
	SELECT txn_id, SUM(qty * price * (discount / 100)) AS total_discount_amount
	FROM sales
	GROUP BY txn_id
    ) AS discount;

-- 5. What is the percentage split of all transactions for members vs non-members?
SELECT ROUND(100 * member_txn / total_txn, 2) AS pct_member_txn, ROUND(100 * nonmember_txn / total_txn, 2) AS pct_nonmember_txn
FROM (
	SELECT COUNT(DISTINCT txn_id) AS total_txn, COUNT(DISTINCT CASE WHEN member = 1 THEN txn_id END) AS member_txn, COUNT(DISTINCT CASE WHEN member = 0 THEN txn_id END) AS nonmember_txn
    FROM sales
    ) AS txn;

-- 6. What is the average revenue for member transactions and non-member transactions?
SELECT member, ROUND(AVG(revenue), 2) AS avg_revenue
FROM (
	SELECT txn_id, member, SUM(qty * price * (discount / 100)) AS revenue
    FROM sales
    GROUP BY txn_id, member
    ) AS revenue
GROUP BY member; 

/* ----------------------------------------
   Case Study Questions C: Product Analysis
   ----------------------------------------*/
-- 1. What are the top 3 products by total revenue before discount?
SELECT p.product_name, SUM(s.qty * s.price) AS total_revenue_before_discount
FROM sales AS s INNER JOIN product_details AS p ON s.prod_id = p.product_id
GROUP BY product_name
ORDER BY total_revenue_before_discount DESC
LIMIT 3;

-- 2. What is the total quantity, revenue and discount for each segment?
SELECT p.category_name, p.segment_name, SUM(s.qty) AS total_quantity, SUM(s.qty * s.price) AS total_revenue, ROUND(SUM(s.qty * s.price * (s.discount / 100)), 2) AS total_discount
FROM sales AS s INNER JOIN product_details AS p ON s.prod_id = p.product_id
GROUP BY p.segment_name, p.category_name;

-- 3. What is the top selling product for each segment?
SELECT segment_name, product_name, total_quantity
FROM (
	SELECT p.segment_name, p.product_name, SUM(s.qty) AS total_quantity, ROW_NUMBER() OVER (PARTITION BY segment_name ORDER BY SUM(s.qty) DESC) AS qty_rank
	FROM sales AS s INNER JOIN product_details AS p ON s.prod_id = p.product_id
	GROUP BY p.segment_name, p.product_name
    ) AS product
WHERE qty_rank = 1;

-- 4. What is the total quantity, revenue and discount for each category?
SELECT p.category_name, SUM(s.qty) AS total_quantity, SUM(s.qty * s.price) AS total_revenue, ROUND(SUM(s.qty * s.price * (s.discount / 100)), 2) AS total_discount
FROM sales AS s INNER JOIN product_details AS p ON s.prod_id = p.product_id
GROUP BY p.category_name;

-- 5. What is the top selling product for each category?
SELECT category_name, product_name, total_quantity
FROM (
	SELECT p.category_name, p.product_name, SUM(s.qty) AS total_quantity, ROW_NUMBER() OVER (PARTITION BY category_name ORDER BY SUM(s.qty) DESC) AS qty_rank
	FROM sales AS s INNER JOIN product_details AS p ON s.prod_id = p.product_id
	GROUP BY p.category_name, p.product_name
    ) AS product
WHERE qty_rank = 1;

-- 6. What is the percentage split of revenue by product for each segment?
SELECT segment_name, product_name, ROUND(100 * product_revenue / SUM(product_revenue) OVER(PARTITION BY segment_name), 2) AS revenue_pct
FROM (
	SELECT p.segment_name, p.product_name, SUM(s.qty * s.price) AS product_revenue
    FROM sales AS s INNER JOIN product_details AS p ON s.prod_id = p.product_id
    GROUP BY segment_name, product_name
    ) AS revenue
ORDER BY segment_name, revenue_pct DESC;

-- 7. What is the percentage split of revenue by segment for each category?
SELECT category_name, segment_name, ROUND(100 * segment_revenue / SUM(segment_revenue) OVER(PARTITION BY category_name), 2) AS revenue_pct
FROM (
	SELECT p.category_name, p.segment_name, SUM(s.qty * s.price) AS segment_revenue
    FROM sales AS s INNER JOIN product_details AS p ON s.prod_id = p.product_id
    GROUP BY category_name, segment_name
    ) AS revenue
ORDER BY category_name, revenue_pct DESC;

-- 8. What is the percentage split of total revenue by category?
SELECT category_name, ROUND(100 * category_revenue / (SELECT SUM(qty * price) FROM sales), 2) AS revenue_pct
FROM (
	SELECT p.category_name, SUM(s.qty * s.price) AS category_revenue
    FROM sales AS s INNER JOIN product_details AS p ON s.prod_id = p.product_id
    GROUP BY category_name
    ) AS revenue
GROUP BY category_name
ORDER BY category_name, revenue_pct DESC;

-- 9. What is the total transaction “penetration” for each product? (hint: penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)
SELECT p.product_id, p.product_name, COUNT(DISTINCT txn_id) AS transaction_penetration, ROUND(100 * COUNT(DISTINCT txn_id) / (SELECT COUNT(DISTINCT txn_id) FROM sales), 2) AS penetration_pct
FROM sales AS s INNER JOIN product_details AS p ON s.prod_id = p.product_id
GROUP BY product_id, product_name
ORDER BY transaction_penetration DESC;

-- 10. What is the most common combination of at least 1 quantity of any 3 products in a single transaction?
SELECT product1, product2, product3, bought_together
FROM (
	WITH cte_product AS (
		SELECT txn_id, product_name
        FROM sales AS s INNER JOIN product_details AS p ON s.prod_id = p.product_id
		)
    SELECT p1.product_name AS product1, p2.product_name AS product2, p3.product_name AS product3, COUNT(*) AS bought_together, ROW_NUMBER() OVER(ORDER BY COUNT(*) DESC) AS combo_rank
    FROM cte_product AS p1 INNER JOIN cte_product AS p2 ON p1.txn_id = p2.txn_id AND p1.product_name != p2.product_name AND p1.product_name < p2.product_name
		INNER JOIN cte_product AS p3 ON p1.txn_id = p3.txn_id AND p1.product_name != p3.product_name AND p2.product_name != p3.product_name AND p1.product_name < p3.product_name AND p2.product_name < p3.product_name
	GROUP BY p1.product_name, p2.product_name, p3.product_name
) AS combo
WHERE combo_rank = 1;

/* ------------------------------------
   Case Study Questions: Bonus Question
   ------------------------------------*/
-- Logic: create a temporary table by filtering sales table by the target month (extract month from start_txn_time), and perform all analyses above using this temporary table. 
-- Each month, modify only the filtering query to generate analysis for the previous month. 

/* ------------------------------------
   Case Study Questions: Bonus Question
   ------------------------------------*/
SELECT pp.product_id, 
	pp.price, 
    CONCAT(ph1.level_text, ' ', ph2.level_text, ' - ', ph3.level_text) AS product_name,
	ph3.id AS category_id, 
    ph2.id AS segment_id, 
    ph1.id AS style_id, 
    ph3.level_text AS category_name, 
    ph2.level_text AS segment_name, 
    ph1.level_text AS style_name
FROM product_hierarchy AS ph1 INNER JOIN product_hierarchy AS ph2 ON ph1.parent_id = ph2.id
	INNER JOIN product_hierarchy AS ph3 ON ph2.parent_id = ph3.id
    INNER JOIN product_prices AS pp ON ph1.id = pp.id;
