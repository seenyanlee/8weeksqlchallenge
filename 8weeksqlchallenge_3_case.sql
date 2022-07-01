/* -------------------------------------
   Case Study Questions B: Data Analysis
   -------------------------------------*/
-- 1. How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) AS NumCustomers
FROM subscriptions;

-- 2. What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT MONTH(start_date) AS month, MONTHNAME(start_date) AS month_name, COUNT(*) AS trial_subscription
FROM subscriptions 
WHERE plan_id = 0
GROUP BY month
ORDER BY month;

-- 3. What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT subscriptions.plan_id, plans.plan_name, IFNULL(COUNT(*), 0) AS count_of_plan
FROM subscriptions LEFT JOIN plans ON subscriptions.plan_id = plans.plan_id
WHERE start_date >= '2021-01-01'
GROUP BY plan_id, plan_name
ORDER BY plan_id;

-- 4. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT COUNT(customer_id) AS customer_count, ROUND(COUNT(customer_id) / (SELECT COUNT(DISTINCT customer_id) AS NumCustomers FROM subscriptions) * 100, 1) AS percentage
FROM subscriptions
WHERE plan_id = 4;

-- 5. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
SELECT COUNT(*) AS churn_count, ROUND(COUNT(customer_id) / (SELECT COUNT(DISTINCT customer_id) AS NumCustomers FROM subscriptions) * 100, 0) AS percentage
FROM (
	SELECT customer_id, plan_id, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date) as plan_rank
    FROM subscriptions
    ) AS subs
WHERE plan_id = 4 AND plan_rank = 2;

-- 6. What is the number and percentage of customer plans after their initial free trial?
SELECT next_plan, COUNT(*) AS plan_count, ROUND(COUNT(*) / (SELECT COUNT(DISTINCT customer_id) AS NumCustomers FROM subscriptions) * 100, 2) AS percentage
FROM (
	SELECT customer_id, plan_id, LEAD(plan_id, 1) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_plan
    FROM subscriptions
    ) AS subs
WHERE next_plan IS NOT NULL AND plan_id = 0
GROUP BY next_plan
ORDER BY next_plan;

-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
SELECT plan_id, plan_name, COUNT(*) AS customer_count, ROUND(COUNT(*) / (SELECT COUNT(DISTINCT customer_id) AS NumCustomers FROM subscriptions) * 100, 2) AS percentage
FROM (
	SELECT customer_id, plan_id, plan_name, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY start_date DESC) AS latest_plan
    FROM subscriptions NATURAL JOIN plans
    WHERE start_date <= '2020-12-31'
    ) AS subs
WHERE latest_plan = 1
GROUP BY plan_id, plan_name
ORDER BY plan_id;

-- 8. How many customers have upgraded to an annual plan in 2020?
SELECT COUNT(*) AS NumCustomers
FROM subscriptions
WHERE plan_id = 3 AND YEAR(start_date) = 2020;

-- 9. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
SELECT ROUND(AVG(DATEDIFF(s2.start_date, s1.start_date)), 0) AS days_on_average
FROM subscriptions AS s1 INNER JOIN subscriptions AS s2 ON s1.customer_id = s2.customer_id
WHERE s1.plan_id = 0 AND s2.plan_id = 3;

-- 10. Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
SELECT CONCAT(days_bucket + 30 * days_bucket, '-', (days_bucket+1) * 30, ' days') AS 30_day_period, count
FROM (
	SELECT ROUND(DATEDIFF(s2.start_date, s1.start_date), 0) DIV 30 AS days_bucket, COUNT(*) AS count
	FROM subscriptions AS s1 INNER JOIN subscriptions AS s2 ON s1.customer_id = s2.customer_id
	WHERE s1.plan_id = 0 AND s2.plan_id = 3
    GROUP BY days_bucket
    ) AS subs
ORDER BY days_bucket;

-- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
SELECT COUNT(*) AS num_customers
FROM (
	SELECT customer_id, LEAD(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY start_date) AS next_plan, start_date
    FROM subscriptions
    WHERE plan_id = 2 
    ) AS subs
WHERE next_plan = 1 AND YEAR(start_date) = 2020;
