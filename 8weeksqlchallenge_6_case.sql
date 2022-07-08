/* ----------------------------------------
   Case Study Questions 2: Digital Analysis
   ----------------------------------------*/
-- 1. How many users are there?
SELECT COUNT(DISTINCT user_id) AS count_users
FROM users;

-- 2. How many cookies does each user have on average?
SELECT AVG(count_cookies) AS avg_cookies
FROM (
	SELECT user_id, COUNT(cookie_id) AS count_cookies
    FROM users
    GROUP BY user_id
    ) AS user_cookie;

-- 3. What is the unique number of visits by all users per month?
SELECT event_year, event_month, COUNT(visit_id) AS num_visits
FROM (
	SELECT YEAR(event_time) AS event_year, MONTH(event_time) AS event_month, visit_id
    FROM events
    ) AS visit_by_month
GROUP BY event_year, event_month
ORDER BY event_year, event_month;

-- 4. What is the number of events for each event type?
SELECT event_type, event_name, COUNT(visit_id) AS num_events
FROM events NATURAL JOIN event_identifier
GROUP BY event_type, event_name;

-- 5. What is the percentage of visits which have a purchase event?
SELECT ROUND(COUNT(DISTINCT visit_id) / (SELECT COUNT(DISTINCT visit_id) FROM events) * 100, 2) AS purchase_percentage
FROM events NATURAL JOIN event_identifier
WHERE event_name = 'Purchase';

-- 6. What is the percentage of visits which view the checkout page but do not have a purchase event?
SELECT ROUND((1 - SUM(purchase) / SUM(view_checkout)) * 100, 2) AS view_checkout_no_purchase_percentage
FROM (
	SELECT visit_id, MAX(CASE WHEN event_type = 1 AND page_id = 12 THEN 1 ELSE 0 END) AS view_checkout, MAX(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS purchase
    FROM events
    GROUP BY visit_id
    ) AS visit_event;

-- 7. What are the top 3 pages by number of views?
SELECT page_id, page_name, COUNT(visit_id) AS views
FROM events NATURAL JOIN page_hierarchy NATURAL JOIN event_identifier
WHERE event_name = 'Page View'
GROUP BY page_id, page_name
ORDER BY views DESC
LIMIT 3;

-- 8. What is the number of views and cart adds for each product category?
SELECT product_category, COUNT(CASE WHEN event_type = 1 THEN 1 ELSE NULL END) AS page_view, COUNT(CASE WHEN event_type = 2 THEN 1 ELSE NULL END) AS cart_adds
FROM events NATURAL JOIN page_hierarchy
WHERE product_category IS NOT NULL
GROUP BY product_category;

-- 9. What are the top 3 products by purchases?
SELECT product_id, page_name, COUNT(*) AS purchase
FROM events NATURAL JOIN page_hierarchy 
WHERE product_id IS NOT NULL AND event_type = 3
GROUP BY product_id, page_name
ORDER BY purchase DESC
LIMIT 3;

/* -----------------------------------------------
   Case Study Questions 3: Product Funnel Analysis
   -----------------------------------------------*/
-- Output table regarding product info
WITH product_events AS (
	SELECT visit_id, page_name, product_category, product_id, SUM(CASE WHEN event_type = 1 THEN 1 ELSE 0 END) AS page_view, SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) AS cart_add
    FROM events NATURAL JOIN page_hierarchy
    WHERE product_id IS NOT NULL
    GROUP BY visit_id, page_name, product_category, product_id
),
purchase_visits AS (
	SELECT DISTINCT visit_id
    FROM events
    WHERE event_type = 3
),
purchase_events AS (
	SELECT product_events.visit_id, page_name, product_category, product_id, page_view, cart_add, CASE WHEN purchase_visits.visit_id IS NOT NULL THEN 1 ELSE 0 END AS purchase
    FROM product_events LEFT JOIN purchase_visits ON product_events.visit_id  = purchase_visits.visit_id
),
product_info AS (
	SELECT page_name AS product_name, product_category, SUM(page_view) AS page_views, SUM(cart_add) AS cart_adds, SUM(CASE WHEN cart_add = 1 AND purchase = 0 THEN 1 ELSE 0 END) AS abandoned, SUM(CASE WHEN cart_add = 1 AND purchase = 1 THEN 1 ELSE 0 END) AS purchases
    FROM purchase_events
    GROUP BY page_name, product_category
)
SELECT *
FROM product_info
ORDER BY product_category, product_name;

-- Output table regarding product category info
WITH product_events AS (
	SELECT visit_id, product_category, product_id, SUM(CASE WHEN event_type = 1 THEN 1 ELSE 0 END) AS page_view, SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) AS cart_add
    FROM events NATURAL JOIN page_hierarchy
    WHERE product_id IS NOT NULL
    GROUP BY visit_id, product_category, product_id
),
purchase_visits AS (
	SELECT DISTINCT visit_id
    FROM events
    WHERE event_type = 3
),
purchase_events AS (
	SELECT product_events.visit_id, product_category, product_id, page_view, cart_add, CASE WHEN purchase_visits.visit_id IS NOT NULL THEN 1 ELSE 0 END AS purchase
    FROM product_events LEFT JOIN purchase_visits ON product_events.visit_id  = purchase_visits.visit_id
),
product_cat_info AS (
	SELECT product_category, SUM(page_view) AS page_views, SUM(cart_add) AS cart_adds, SUM(CASE WHEN cart_add = 1 AND purchase = 0 THEN 1 ELSE 0 END) AS abandoned, SUM(CASE WHEN cart_add = 1 AND purchase = 1 THEN 1 ELSE 0 END) AS purchases
    FROM purchase_events
    GROUP BY product_category
)
SELECT *
FROM product_cat_info
ORDER BY product_category;

-- 1. Which product had the most views, cart adds and purchases?
(SELECT * 
FROM product_info
ORDER BY page_views DESC
LIMIT 1)
UNION
(SELECT * 
FROM product_info
ORDER BY cart_adds DESC
LIMIT 1)
UNION
(SELECT * 
FROM product_info
ORDER BY purchases DESC
LIMIT 1);

-- 2. Which product was most likely to be abandoned?
SELECT product_name
FROM product_info
ORDER BY abandoned DESC
LIMIT 1;

-- 3. Which product had the highest view to purchase percentage?
SELECT product_name, ROUND(100 * page_views / purchases, 2) AS view_to_purchase
FROM product_info
ORDER BY view_to_purchase DESC
LIMIT 1;

-- 4. What is the average conversion rate from view to cart add?
SELECT ROUND(100 * AVG(cart_adds / page_views), 2) AS view_to_cart_conversion
FROM product_info;

-- 5. What is the average conversion rate from cart add to purchase?
SELECT ROUND(100 * AVG(purchases / cart_adds), 2) AS view_to_cart_conversion
FROM product_info;

/* ------------------------------------------
   Case Study Questions 4: Campaigns Analysis
   ------------------------------------------*/
CREATE TEMPORARY TABLE campaign_analysis
SELECT user_id, 
	visit_id, 
    MIN(event_time) AS visit_start_time, 
    SUM(CASE WHEN event_type = 1 THEN 1 ELSE 0 END) AS page_views, 
    SUM(CASE WHEN event_type = 2 THEN 1 ELSE 0 END) AS cart_adds, 
    SUM(CASE WHEN event_type = 3 THEN 1 ELSE 0 END) AS purchase, 
    campaign_name,
    SUM(CASE WHEN event_type = 4 THEN 1 ELSE 0 END) AS impression,
    SUM(CASE WHEN event_type = 5 THEN 1 ELSE 0 END) AS click,
    GROUP_CONCAT(CASE WHEN product_id IS NOT NULL AND event_type = 2 THEN page_name ELSE NULL END ORDER BY sequence_number, ', ') AS cart_products
FROM users NATURAL JOIN events
	LEFT JOIN page_hierarchy ON events.page_id = page_hierarchy.page_id
    LEFT JOIN campaign_identifier ON events.event_time BETWEEN campaign_identifier.start_date AND campaign_identifier.end_date
GROUP BY visit_id, user_id, campaign_name;

-- Insight 1: number of visits during each campaign
SELECT campaign_name, COUNT(visit_id) AS visits_during_campaign
FROM campaign_analysis
GROUP BY campaign_name;
-- --  Half Off - Treat Your Shellf(ish) seems to be the most successful campaign, with almost 10 times as many visits as the least successful campaign has. 

-- Insight 2: number of users who made a purchase during each campaign
SELECT campaign_name, COUNT(DISTINCT user_id) AS users_with_purchase
FROM campaign_analysis
GROUP BY campaign_name;
-- -- Most users made a purchase during the Half Off - Treat Your Shellf(ish) campaign. 

-- Insight 3: impression-to-click conversion rate of each campaign
SELECT campaign_name, ROUND(100 * SUM(click) / SUM(impression), 2) AS impression_click_conversion
FROM campaign_analysis
GROUP BY campaign_name;
-- -- BOGOF - Fishing For Compliments campaign has the highest conversion rate at 84.62%. 

-- Insight 4: relationship between impression-to-click conversion rate and purchase rate
SELECT campaign_name, ROUND(100 * SUM(click) / SUM(impression), 2) AS impression_click_conversion, ROUND(100 * SUM(purchase) / COUNT(*), 2) AS purchase_rate
FROM campaign_analysis
GROUP BY campaign_name
ORDER BY impression_click_conversion DESC;
-- -- The overall purchase rate is around 50%; a higher impression-to-click conversion rate does not lead to higher purchase rate.

-- Insight 5: comparison of purchase rate for each campaign with and without ad impression
SELECT campaign_name, 
	ROUND(100 * SUM(CASE WHEN impression = 1 THEN purchase ELSE 0 END) / COUNT(CASE WHEN impression = 1 THEN 1 ELSE NULL END), 2) AS purchase_rate_with_impression,
    ROUND(100 * SUM(CASE WHEN impression = 0 THEN purchase ELSE 0 END) / COUNT(CASE WHEN impression = 0 THEN 1 ELSE NULL END), 2) AS purchase_rate_without_impression
FROM campaign_analysis
GROUP BY campaign_name;
-- -- For all campaigns, the purchase rate with ad impression nearly more than doubled that without ad impression. 