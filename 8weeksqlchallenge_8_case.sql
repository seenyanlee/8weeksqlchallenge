/* ------------------------------------------------------
   Case Study Questions A: Data Exploration and Cleansing
   ------------------------------------------------------*/
-- 1. Update the fresh_segments.interest_metrics table by modifying the month_year column to be a date data type with the start of the month
UPDATE interest_metrics
SET month_year = STR_TO_DATE(CONCAT('01-', month_year), '%d-%m-%Y');

-- 2. What is count of records in the fresh_segments.interest_metrics for each month_year value sorted in chronological order (earliest to latest) with the null values appearing first?
SELECT month_year, COUNT(*) AS count_of_records
FROM interest_metrics
GROUP BY month_year
ORDER BY month_year;

-- 3. What do you think we should do with these null values in the fresh_segments.interest_metrics
-- -- Since the proportion of entries with NULL values is small, these rows can be dropped. 

-- 4. How many interest_id values exist in the fresh_segments.interest_metrics table but not in the fresh_segments.interest_map table? What about the other way around?
SELECT COUNT(CASE WHEN interest_map.id IS NULL THEN 1 ELSE NULL END) AS interest_not_in_interest_map, COUNT(CASE WHEN interest_metrics.interest_id IS NULL THEN 1 ELSE NULL END) AS interest_not_in_interest_metrics
FROM interest_metrics FULL JOIN interest_map ON interest_metrics.interest_id = interest_map.id;

-- 5. Summarise the id values in the fresh_segments.interest_map by its total record count in this table
SELECT id, COUNT(*) AS total_record_count
FROM interest_map AS map INNER JOIN interest_metrics AS metrics ON map.id = metrics.interest_id
GROUP BY id
ORDER BY total_record_count DESC;

-- 6. What sort of table join should we perform for our analysis and why? Check your logic by checking the rows where interest_id = 21246 in your joined output and include all columns from fresh_segments.interest_metrics and all columns from fresh_segments.interest_map except from the id column.

-- 7. Are there any records in your joined table where the month_year value is before the created_at value from the fresh_segments.interest_map table? Do you think these values are valid and why?

/* -----------------------------------------
   Case Study Questions B: Interest Analysis
   -----------------------------------------*/
-- 1. Which interests have been present in all month_year dates in our dataset?
SELECT COUNT(DISTINCT month_year) AS total_months
FROM interest_metrics
WHERE month_year IS NOT NULL
ORDER BY total_months DESC
LIMIT 1; -- find highest total_months value (14)

SELECT interest_id
FROM (
	SELECT interest_id, COUNT(DISTINCT month_year) AS total_months
    FROM interest_metrics
    WHERE month_year IS NOT NULL
    GROUP BY interest_id
    ) AS interest_months
WHERE total_months = 14;

-- 2. Using this same total_months measure - calculate the cumulative percentage of all records starting at 14 months - which total_months value passes the 90% cumulative percentage value?
SELECT total_months, COUNT(DISTINCT interest_id) AS interest_count, ROUND(100 * SUM(COUNT(DISTINCT interest_id)) OVER(ORDER BY total_months DESC) / SUM(COUNT(DISTINCT interest_id)) OVER(), 2) AS cumulative_pct 
FROM (
	SELECT interest_id, COUNT(DISTINCT month_year) AS total_months
    FROM interest_metrics
    WHERE month_year IS NOT NULL
    GROUP BY interest_id
    ) AS interest_months
GROUP BY total_months;

-- 3. If we were to remove all interest_id values which are lower than the total_months value we found in the previous question - how many total data points would we be removing?
SELECT SUM(interest_count) AS interest_to_remove
FROM (
	SELECT total_months, COUNT(DISTINCT interest_id) AS interest_count, ROUND(100 * SUM(COUNT(DISTINCT interest_id)) OVER(ORDER BY total_months DESC) / SUM(COUNT(DISTINCT interest_id)) OVER(), 2) AS cumulative_pct 
	FROM (
		SELECT interest_id, COUNT(DISTINCT month_year) AS total_months
		FROM interest_metrics
		WHERE month_year IS NOT NULL
		GROUP BY interest_id
		) AS interest_months
	GROUP BY total_months
	) AS interest_cumulative_pct
WHERE cumulative_pct > 90;

-- 4. Does this decision make sense to remove these data points from a business perspective? Use an example where there are all 14 months present to a removed interest example for your arguments - think about what it means to have less months present from a segment perspective.

-- 5. After removing these interests - how many unique interests are there for each month?
DROP TABLE IF EXISTS interest_metrics_trimmed;
CREATE TEMPORARY TABLE interest_metrics_trimmed
SELECT *
FROM interest_metrics
WHERE month_year IS NOT NULL AND interest_id IN (SELECT interest_id FROM interest_metrics GROUP BY interest_id HAVING COUNT(interest_id) > 6);

SELECT month_year, COUNT(DISTINCT interest_id) AS unique_interest
FROM interest_metrics_trimmed
GROUP BY month_year;

/* ----------------------------------------
   Case Study Questions C: Segment Analysis
   ----------------------------------------*/
-- 1. Using our filtered dataset by removing the interests with less than 6 months worth of data, which are the top 10 and bottom 10 interests which have the largest composition values in any month_year? Only use the maximum composition value for each interest but you must keep the corresponding month_year
SELECT *
FROM (
	SELECT month_year, interest_id, interest_name, composition
	FROM (
		SELECT month_year, interest_id, interest_name, composition, RANK() OVER(PARTITION BY interest_name ORDER BY composition DESC) AS composition_rank
		FROM interest_metrics_trimmed AS metrics LEFT JOIN interest_map AS map ON metrics.interest_id = map.id
		) AS composition_rank
	WHERE composition_rank = 1
    ) AS max_composition
ORDER BY composition DESC
LIMIT 10; -- top 10 interests

SELECT *
FROM (
	SELECT month_year, interest_id, interest_name, composition
	FROM (
		SELECT month_year, interest_id, interest_name, composition, RANK() OVER(PARTITION BY interest_name ORDER BY composition DESC) AS composition_rank
		FROM interest_metrics_trimmed AS metrics LEFT JOIN interest_map AS map ON metrics.interest_id = map.id
		) AS composition_rank
	WHERE composition_rank = 1
    ) AS max_composition
ORDER BY composition 
LIMIT 10; -- bottom 10 interests

-- 2. Which 5 interests had the lowest average ranking value?
SELECT interest_id, interest_name
FROM (
	SELECT interest_id, interest_name, AVG(ranking) AS avg_ranking
    FROM interest_metrics_trimmed AS metrics LEFT JOIN interest_map AS map ON metrics.interest_id = map.id
    GROUP BY interest_id, interest_name
    ) AS avg_interest_ranking
ORDER BY avg_ranking DESC 
LIMIT 5;

-- 3. Which 5 interests had the largest standard deviation in their percentile_ranking value?
CREATE TEMPORARY TABLE interest_stddev
SELECT interest_id, interest_name, STDDEV(percentile_ranking) AS std_dev_ranking
FROM interest_metrics_trimmed AS metrics LEFT JOIN interest_map AS map ON metrics.interest_id = map.id
GROUP BY interest_id, interest_name
ORDER BY std_dev_ranking DESC
LIMIT 5;

-- 4. For the 5 interests found in the previous question - what was minimum and maximum percentile_ranking values for each interest and its corresponding year_month value? Can you describe what is happening for these 5 interests?
SELECT month_year, interest_name, percentile_ranking
FROM (
	SELECT month_year, interest_id, interest_name, percentile_ranking, RANK() OVER(PARTITION BY interest_id ORDER BY percentile_ranking) AS min_percentile_ranking, RANK() OVER(PARTITION BY interest_id ORDER BY percentile_ranking DESC) AS max_percentile_ranking
	FROM interest_metrics_trimmed AS metrics LEFT JOIN interest_map AS map ON metrics.interest_id = map.id
    WHERE interest_id IN (SELECT interest_id FROM interest_stddev)
	 ) AS percentile_rank
WHERE max_percentile_ranking = 1 OR min_percentile_ranking = 1;

-- 5. How would you describe our customers in this segment based off their composition and ranking values? What sort of products or services should we show to these customers and what should we avoid?
   
/* --------------------------------------
   Case Study Questions D: Index Analysis
   --------------------------------------*/
-- 1. What is the top 10 interests by the average composition for each month?
CREATE TEMPORARY TABLE avg_composition_top10
SELECT month_year, interest_id, interest_name, avg_composition
FROM (
	SELECT month_year, interest_id, interest_name, avg_composition, RANK() OVER(PARTITION BY month_year ORDER BY avg_composition DESC) AS avg_composition_rank
	FROM (
		SELECT month_year, interest_id, interest_name, ROUND(composition / index_value, 2) AS avg_composition
		FROM interest_metrics AS metrics LEFT JOIN interest_map AS map ON metrics.interest_id = map.id
		WHERE month_year IS NOT NULL AND interest_id IN (SELECT interest_id FROM interest_metrics GROUP BY interest_id HAVING COUNT(interest_id) > 6)
		GROUP BY month_year, interest_id, interest_name, composition, index_value
		) AS avg_composition
	) AS avg_composition_rank
WHERE avg_composition_rank BETWEEN 1 AND 10
GROUP BY month_year, interest_id, interest_name, avg_composition
ORDER BY month_year, avg_composition DESC;

-- 2. For all of these top 10 interests - which interest appears the most often?
SELECT interest_name, COUNT(*) AS appearance
FROM avg_composition_top10
GROUP BY interest_name
ORDER BY appearance DESC
LIMIT 1;

-- 3. What is the average of the average composition for the top 10 interests for each month?
SELECT month_year, AVG(avg_composition) 
FROM avg_composition_top10
GROUP BY month_year
ORDER BY month_year;

-- 4. What is the 3 month rolling average of the max average composition value from September 2018 to August 2019 and include the previous top ranking interests in the same output shown below.
SELECT *
FROM (
	SELECT month_year, interest_name, avg_composition AS max_index_composition, 
		ROUND(AVG(avg_composition) OVER(ORDER BY month_year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS 3_month_moving_avg,
		CONCAT(LAG(interest_name) OVER(ORDER BY month_year), ': ', LAG(avg_composition) OVER(ORDER BY month_year)) AS 1_month_ago,
		CONCAT(LAG(interest_name, 2) OVER(ORDER BY month_year), ': ', LAG(avg_composition, 2) OVER(ORDER BY month_year)) AS 2_months_ago
	FROM (
		SELECT month_year, interest_id, interest_name, avg_composition, RANK() OVER(PARTITION BY month_year ORDER BY avg_composition DESC) AS avg_composition_rank
		FROM (
			SELECT month_year, interest_id, interest_name, ROUND(composition / index_value, 2) AS avg_composition
			FROM interest_metrics AS metrics LEFT JOIN interest_map AS map ON metrics.interest_id = map.id
			WHERE month_year IS NOT NULL AND interest_id IN (SELECT interest_id FROM interest_metrics GROUP BY interest_id HAVING COUNT(interest_id) > 6)
			GROUP BY month_year, interest_id, interest_name, composition, index_value
			) AS avg_composition
		GROUP BY month_year, interest_id, interest_name, avg_composition
		) AS composition_max
	WHERE avg_composition_rank = 1
	) AS max_composition
WHERE month_year > '2018-08-01'
ORDER BY month_year;

-- 5. Provide a possible reason why the max average composition might change from month to month? Could it signal something is not quite right with the overall business model for Fresh Segments?
