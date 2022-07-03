/* --------------------------------------------------
   Case Study Questions A: Customer Nodes Exploration
   --------------------------------------------------*/
-- 1. How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT node_id) AS unique_nodes
FROM customer_nodes;

-- 2 What is the number of nodes per region?
SELECT region_id, region_name, COUNT(node_id) AS num_nodes
FROM customer_nodes NATURAL JOIN regions
GROUP BY region_id, region_name
ORDER BY region_id;

-- 3. How many customers are allocated to each region?
SELECT region_id, COUNT(customer_id) AS num_customers
FROM customer_nodes
GROUP BY region_id
ORDER BY region_id;

-- 4. How many days on average are customers reallocated to a different node?
SELECT AVG(diff) AS avg_days
FROM (
	SELECT customer_id, node_id, DATEDIFF(end_date, start_date) AS diff
    FROM customer_nodes
    WHERE end_date != '9999-12-31'
    GROUP BY customer_id, node_id, start_date, end_date
    ) AS node_diff;

-- 5. What is the median, 80th and 95th percentile for this same reallocation days metric for each region?
SELECT *
FROM (	
    SELECT region_id, region_name, diff AS reallocation_days, ROUND(PERCENT_RANK() OVER(PARTITION BY region_id ORDER BY diff),2)AS percentile
	FROM (
		SELECT region_id, node_id, DATEDIFF(end_date, start_date) AS diff
		FROM customer_nodes
		WHERE end_date != '9999-12-31'
		GROUP BY region_id, node_id, start_date, end_date
		) AS node_diff
	NATURAL JOIN regions
	GROUP BY region_id, region_name, diff
    ) AS node_percentile
WHERE percentile IN (0.5,0.8) OR percentile = 0.97;

/* ---------------------------------------------
   Case Study Questions A: Customer Transactions
   ---------------------------------------------*/
-- 1. What is the unique count and total amount for each transaction type?
SELECT txn_type, COUNT(*) AS unique_count, SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY txn_type;

-- 2. What is the average total historical deposit counts and amounts for all customers?
SELECT ROUND(AVG(deposit_count),2) AS avg_deposit_count, ROUND(AVG(deposit_amount),2) AS avg_deposit_amount
FROM (
	SELECT customer_id, COUNT(*) AS deposit_count, SUM(txn_amount) AS deposit_amount
    FROM customer_transactions
    WHERE txn_type = 'deposit'
    GROUP BY customer_id
    ) AS deposit;

-- 3. For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
SELECT txn_month, COUNT(*) AS num_customers
FROM (
	SELECT customer_id, MONTH(txn_date) AS txn_month
    FROM customer_transactions
	GROUP BY customer_id, txn_month
    HAVING (SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE NULL END) > 1 AND SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE NULL END) = 1) 
		OR (SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE NULL END) > 1 AND SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE NULL END) = 1)
    ) AS txn_by_month
GROUP BY txn_month
ORDER BY txn_month;

-- 4. What is the closing balance for each customer at the end of the month?
CREATE TEMPORARY TABLE closing_balance
SELECT customer_id, txn_month, net_txn, SUM(net_txn) OVER(PARTITION BY customer_id ORDER BY txn_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS closing_balance
FROM (
	SELECT customer_id, MONTH(txn_date) AS txn_month, SUM(CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE (-txn_amount) END) AS net_txn
	FROM customer_transactions
    GROUP BY customer_id, txn_month
	) AS net_txn_by_month
GROUP BY customer_id, txn_month, net_txn
ORDER BY customer_id, txn_month;

-- 5. What is the percentage of customers who increase their closing balance by more than 5%?
SELECT ROUND(COUNT(DISTINCT customer_id) / (SELECT COUNT(DISTINCT customer_id) FROM customer_transactions) * 100,2) AS customer_percentange
FROM (
	SELECT *, LAG(closing_balance) OVER(PARTITION BY customer_id ORDER BY txn_month) AS prev_balance
    FROM closing_balance
    ) AS prev_closing_balance
WHERE closing_balance >= prev_balance * 1.05;

/* -------------------------------------------------
   Case Study Questions C: Data Allocation Challenge
   -------------------------------------------------*/
-- Table for running balance after each transaction
CREATE TEMPORARY TABLE running_balance
SELECT customer_id, txn_month, net_txn, SUM(net_txn) OVER(PARTITION BY customer_id ORDER BY txn_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_balance
FROM (
	SELECT customer_id, MONTH(txn_date) AS txn_month, txn_date, CASE WHEN txn_type = 'deposit' THEN txn_amount ELSE (-txn_amount) END AS net_txn
	FROM customer_transactions
    ORDER BY customer_id, txn_date
	) AS realtime_balance
GROUP BY customer_id, txn_date, net_txn
ORDER BY customer_id, txn_month;  
   
-- Reuse the temporary table closing_balance for customer balance at the end of each month

-- Generate min, max, and average running balance for each customer
SELECT customer_id, txn_month, MIN(running_balance) AS min_running_balance, MAX(running_balance) AS max_running_balance, AVG(running_balance) AS avg_running_balance
FROM running_balance
GROUP BY customer_id, txn_month;

-- Option 1: Data is allocated based off the amount of money at the end of the previous month
SELECT txn_month, SUM(IF(closing_balance > 0, closing_balance, 0)) AS data_allocated_by_monthly_balance
FROM closing_balance
GROUP BY txn_month
ORDER BY txn_month;

-- Option 2: Data is allocated on the average amount of money kept in the account in the previous 30 days
SELECT txn_month, ROUND(SUM(IF(avg_running_balance > 0, avg_running_balance, 0))) AS data_allocated_by_avg
FROM (
	SELECT customer_id, txn_month, AVG(running_balance) AS avg_running_balance
	FROM running_balance
	GROUP BY customer_id, txn_month
    ) AS avg_balance
GROUP BY txn_month
ORDER BY txn_month;

-- Option 3: Data is updated real-time
SELECT txn_month, SUM(IF(running_balance > 0, running_balance, 0)) AS data_allocated_by_running_balance
FROM running_balance
GROUP BY txn_month
ORDER BY txn_month;
