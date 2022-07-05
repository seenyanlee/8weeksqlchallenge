/* -------------------------------------------
   Case Study Questions 1: Data Cleaning Steps
   -------------------------------------------*/
DROP TABLE IF EXISTS clean_weekly_sales;
CREATE TABLE clean_weekly_sales
SELECT week_date, 
	CASE WHEN YEAR(week_date) = 2020 THEN FLOOR(DATEDIFF((week_date - (week_date - DATE('2020-01-01')) % 7), DATE('2020-01-01')) / 7)
    WHEN YEAR(week_date) = 2019 THEN FLOOR(DATEDIFF((week_date - (week_date - DATE('2019-01-01')) % 7), DATE('2019-01-01')) / 7)
    ELSE FLOOR(DATEDIFF((week_date - (week_date - DATE('2018-01-01')) % 7), DATE('2018-01-01')) / 7) END AS week_number,
    MONTH(week_date) AS month_number,
    YEAR(week_date) AS calendar_year,
    region,
    platform,
    segment,
    CASE WHEN segment LIKE '%1' THEN 'Young Adults'
    WHEN segment LIKE '%2' THEN 'Middle Aged'
    WHEN segment LIKE '%3' OR segment LIKE '%4' THEN 'Retirees'
    ELSE 'Unknown' END AS age_band,
    CASE WHEN segment LIKE 'C%' THEN 'Couples'
    WHEN segment LIKE 'F%' THEN 'Families'
    ELSE 'Unknown' END AS demographic,
    customer_type,
    transactions,
    sales,
    ROUND(sales / transactions, 2) AS avg_transaction
FROM (
	SELECT STR_TO_DATE(week_date, "%e/%m/%y") AS week_date, region, platform, segment, customer_type, transactions, sales 
    FROM weekly_sales
    ) AS week_date_modified;

/* ----------------------------------------
   Case Study Questions 2: Data Exploration
   ----------------------------------------*/
-- 1. What day of the week is used for each week_date value?
SELECT DISTINCT DAYNAME(week_date)
FROM clean_weekly_sales;

-- 2. What range of week numbers are missing from the dataset?
WITH RECURSIVE seq AS (SELECT 1 AS value UNION ALL SELECT value + 1 FROM seq WHERE value < 52) -- Generate a series of numbers (1-52) recursively
SELECT DISTINCT seq.value
FROM seq LEFT OUTER JOIN clean_weekly_sales ON seq.value = clean_weekly_sales.week_number
WHERE clean_weekly_sales.week_number IS NULL;

-- 3. How many total transactions were there for each year in the dataset?
SELECT calendar_year, COUNT(*) AS total_transaction
FROM clean_weekly_sales
GROUP BY calendar_year;

-- 4. What is the total sales for each region for each month?
SELECT region, calendar_year, month_number, SUM(sales) AS total_sales
FROM clean_weekly_sales
GROUP BY region, calendar_year, month_number
ORDER BY region, calendar_year, month_number;

-- 5. What is the total count of transactions for each platform
SELECT platform, COUNT(*) AS couont_transaction
FROM clean_weekly_sales
GROUP BY platform;

-- 6. What is the percentage of sales for Retail vs Shopify for each month?
SELECT calendar_year, month_number, ROUND(100 * MAX(CASE WHEN platform = 'Retail' THEN sum_sales ELSE NULL END) / SUM(sum_sales), 2) AS retail_percentage, ROUND(100 * MAX(CASE WHEN platform = 'Shopify' THEN sum_sales ELSE NULL END) / SUM(sum_sales), 2) AS shopify_percentage
FROM (
	SELECT calendar_year, month_number, platform, SUM(sales) AS sum_sales
    FROM clean_weekly_sales
    GROUP BY calendar_year, month_number, platform
    ) AS sales_month
GROUP BY calendar_year, month_number;

-- 7. What is the percentage of sales by demographic for each year in the dataset?
SELECT calendar_year, month_number, ROUND(100 * MAX(CASE WHEN demographic = 'Couples' THEN sum_sales ELSE NULL END) / SUM(sum_sales), 2) AS couple_percentage, 
	ROUND(100 * MAX(CASE WHEN demographic = 'Families' THEN sum_sales ELSE NULL END) / SUM(sum_sales), 2) AS family_percentage,
    ROUND(100 * MAX(CASE WHEN demographic = 'Unknown' THEN sum_sales ELSE NULL END) / SUM(sum_sales), 2) AS unknown_percentage
FROM (
	SELECT calendar_year, month_number, demographic, SUM(sales) AS sum_sales
    FROM clean_weekly_sales
    GROUP BY calendar_year, month_number, demographic
    ) AS sales_month
GROUP BY calendar_year, month_number;

-- 8. Which age_band and demographic values contribute the most to Retail sales?
SELECT age_band, demographic, SUM(sales) AS total_sales, ROUND(100 * SUM(sales) / SUM(SUM(sales)) OVER(), 2) AS percentage
FROM clean_weekly_sales
WHERE platform = 'Retail'
GROUP BY age_band, demographic
ORDER BY percentage DESC;

-- 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
SELECT calendar_year, platform, ROUND(SUM(sales) / SUM(transactions), 0) AS avg_transaction_size
FROM clean_weekly_sales
GROUP BY calendar_year, platform;
    -- use overall sum of sales divided by sum of transactions to find the average transaction size
    
/* ------------------------------------------------
   Case Study Questions 3: DBefore & After Analysis
   ------------------------------------------------*/
-- 1. What is the total sales for the 4 weeks before and after 2020-06-15? What is the growth or reduction rate in actual values and percentage of sales?
SELECT DISTINCT week_number
FROM clean_weekly_sales
WHERE week_date = '2020-06-15'; -- week number is 23

SELECT SUM(CASE WHEN week_number BETWEEN 19 AND 22 THEN sum_sales END) AS sales_before, 
	SUM(CASE WHEN week_number BETWEEN 23 AND 26 THEN sum_sales END) AS sales_after, 
	SUM(CASE WHEN week_number BETWEEN 23 AND 26 THEN sum_sales END) - SUM(CASE WHEN week_number BETWEEN 19 AND 22 THEN sum_sales END) AS growth_actual_value,
    ROUND(100 * (SUM(CASE WHEN week_number BETWEEN 23 AND 26 THEN sum_sales END) - SUM(CASE WHEN week_number BETWEEN 19 AND 22 THEN sum_sales END)) / SUM(CASE WHEN week_number BETWEEN 19 AND 22 THEN sum_sales END), 2) AS growth_percentage
FROM (
	SELECT week_date, week_number, SUM(sales) AS sum_sales
    FROM clean_weekly_sales
    WHERE week_number >= 19 AND week_number <= 26 AND calendar_year = 2020
    GROUP BY week_date, week_number
    ) AS sales;

-- 2. What about the entire 12 weeks before and after?
SELECT SUM(CASE WHEN week_number BETWEEN 11 AND 22 THEN sum_sales END) AS sales_before, 
	SUM(CASE WHEN week_number BETWEEN 23 AND 34 THEN sum_sales END) AS sales_after, 
	SUM(CASE WHEN week_number BETWEEN 23 AND 34 THEN sum_sales END) - SUM(CASE WHEN week_number BETWEEN 11 AND 22 THEN sum_sales END) AS growth_actual_value,
    ROUND(100 * (SUM(CASE WHEN week_number BETWEEN 23 AND 34 THEN sum_sales END) - SUM(CASE WHEN week_number BETWEEN 11 AND 22 THEN sum_sales END)) / SUM(CASE WHEN week_number BETWEEN 11 AND 22 THEN sum_sales END), 2) AS growth_percentage
FROM (
	SELECT week_date, week_number, SUM(sales) AS sum_sales
    FROM clean_weekly_sales
    WHERE week_number >= 11 AND week_number <= 34 AND calendar_year = 2020
    GROUP BY week_date, week_number
    ) AS sales;

-- 3. How do the sale metrics for these 2 periods before and after compare with the previous years in 2018 and 2019?
-- Comparing 4 weeks before and after June 15th
SELECT calendar_year,
	SUM(CASE WHEN week_number BETWEEN 19 AND 22 THEN sum_sales END) AS sales_before, 
	SUM(CASE WHEN week_number BETWEEN 23 AND 26 THEN sum_sales END) AS sales_after, 
	SUM(CASE WHEN week_number BETWEEN 23 AND 26 THEN sum_sales END) - SUM(CASE WHEN week_number BETWEEN 19 AND 22 THEN sum_sales END) AS growth_actual_value,
    ROUND(100 * (SUM(CASE WHEN week_number BETWEEN 23 AND 26 THEN sum_sales END) - SUM(CASE WHEN week_number BETWEEN 19 AND 22 THEN sum_sales END)) / SUM(CASE WHEN week_number BETWEEN 19 AND 22 THEN sum_sales END), 2) AS growth_percentage
FROM (
	SELECT calendar_year, week_date, week_number, SUM(sales) AS sum_sales
    FROM clean_weekly_sales
    WHERE week_number >= 19 AND week_number <= 26 
    GROUP BY calendar_year, week_date, week_number
    ) AS sales
GROUP BY calendar_year;

-- Comparing 12 weeks before and after June 15th
SELECT calendar_year,
	SUM(CASE WHEN week_number BETWEEN 11 AND 22 THEN sum_sales END) AS sales_before, 
	SUM(CASE WHEN week_number BETWEEN 23 AND 34 THEN sum_sales END) AS sales_after, 
	SUM(CASE WHEN week_number BETWEEN 23 AND 34 THEN sum_sales END) - SUM(CASE WHEN week_number BETWEEN 11 AND 22 THEN sum_sales END) AS growth_actual_value,
    ROUND(100 * (SUM(CASE WHEN week_number BETWEEN 23 AND 34 THEN sum_sales END) - SUM(CASE WHEN week_number BETWEEN 11 AND 22 THEN sum_sales END)) / SUM(CASE WHEN week_number BETWEEN 11 AND 22 THEN sum_sales END), 2) AS growth_percentage
FROM (
	SELECT calendar_year, week_date, week_number, SUM(sales) AS sum_sales
    FROM clean_weekly_sales
    WHERE week_number >= 11 AND week_number <= 34 
    GROUP BY calendar_year, week_date, week_number
    ) AS sales
GROUP BY calendar_year;

-- For both periods, sales appear to have grown from the same time period in previous years. 
