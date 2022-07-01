-- SCHEMA --
CREATE SCHEMA pizza_runner;
SET search_path = pizza_runner;

DROP TABLE IF EXISTS runners;
CREATE TABLE runners (
  runner_id INTEGER,
  registration_date DATE
);
INSERT INTO runners
  (runner_id, registration_date)
VALUES
  (1, '2021-01-01'),
  (2, '2021-01-03'),
  (3, '2021-01-08'),
  (4, '2021-01-15');


DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
  order_id INTEGER,
  customer_id INTEGER,
  pizza_id INTEGER,
  exclusions VARCHAR(4),
  extras VARCHAR(4),
  order_time TIMESTAMP
);

INSERT INTO customer_orders
  (order_id, customer_id, pizza_id, exclusions, extras, order_time)
VALUES
  ('1', '101', '1', '', '', '2020-01-01 18:05:02'),
  ('2', '101', '1', '', '', '2020-01-01 19:00:52'),
  ('3', '102', '1', '', '', '2020-01-02 23:51:23'),
  ('3', '102', '2', '', NULL, '2020-01-02 23:51:23'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '1', '4', '', '2020-01-04 13:23:46'),
  ('4', '103', '2', '4', '', '2020-01-04 13:23:46'),
  ('5', '104', '1', 'null', '1', '2020-01-08 21:00:29'),
  ('6', '101', '2', 'null', 'null', '2020-01-08 21:03:13'),
  ('7', '105', '2', 'null', '1', '2020-01-08 21:20:29'),
  ('8', '102', '1', 'null', 'null', '2020-01-09 23:54:33'),
  ('9', '103', '1', '4', '1, 5', '2020-01-10 11:22:59'),
  ('10', '104', '1', 'null', 'null', '2020-01-11 18:34:49'),
  ('10', '104', '1', '2, 6', '1, 4', '2020-01-11 18:34:49');


DROP TABLE IF EXISTS runner_orders;
CREATE TABLE runner_orders (
  order_id INTEGER,
  runner_id INTEGER,
  pickup_time VARCHAR(19),
  distance VARCHAR(7),
  duration VARCHAR(10),
  cancellation VARCHAR(23)
);

INSERT INTO runner_orders
  (order_id, runner_id, pickup_time, distance, duration, cancellation)
VALUES
  ('1', '1', '2020-01-01 18:15:34', '20km', '32 minutes', ''),
  ('2', '1', '2020-01-01 19:10:54', '20km', '27 minutes', ''),
  ('3', '1', '2020-01-03 00:12:37', '13.4km', '20 mins', NULL),
  ('4', '2', '2020-01-04 13:53:03', '23.4', '40', NULL),
  ('5', '3', '2020-01-08 21:10:57', '10', '15', NULL),
  ('6', '3', 'null', 'null', 'null', 'Restaurant Cancellation'),
  ('7', '2', '2020-01-08 21:30:45', '25km', '25mins', 'null'),
  ('8', '2', '2020-01-10 00:15:02', '23.4 km', '15 minute', 'null'),
  ('9', '2', 'null', 'null', 'null', 'Customer Cancellation'),
  ('10', '1', '2020-01-11 18:50:20', '10km', '10minutes', 'null');


DROP TABLE IF EXISTS pizza_names;
CREATE TABLE pizza_names (
  pizza_id INTEGER,
  pizza_name TEXT
);
INSERT INTO pizza_names
  (pizza_id, pizza_name)
VALUES
  (1, 'Meatlovers'),
  (2, 'Vegetarian');


DROP TABLE IF EXISTS pizza_recipes;
CREATE TABLE pizza_recipes (
  pizza_id INTEGER,
  toppings TEXT
);
INSERT INTO pizza_recipes
  (pizza_id, toppings)
VALUES
  (1, '1, 2, 3, 4, 5, 6, 8, 10'),
  (2, '4, 6, 7, 9, 11, 12');


DROP TABLE IF EXISTS pizza_toppings;
CREATE TABLE pizza_toppings (
  topping_id INTEGER,
  topping_name TEXT
);
INSERT INTO pizza_toppings
  (topping_id, topping_name)
VALUES
  (1, 'Bacon'),
  (2, 'BBQ Sauce'),
  (3, 'Beef'),
  (4, 'Cheese'),
  (5, 'Chicken'),
  (6, 'Mushrooms'),
  (7, 'Onions'),
  (8, 'Pepperoni'),
  (9, 'Peppers'),
  (10, 'Salami'),
  (11, 'Tomatoes'),
  (12, 'Tomato Sauce');
  -- SCHEMA --
  
  -- DATA CLEANING --
  -- Clean table: customer_orders
CREATE TABLE customer_orders_cleaned (
  order_id INTEGER,
  customer_id INTEGER,
  pizza_id INTEGER,
  exclusions VARCHAR(4),
  extras VARCHAR(4),
  order_time TIMESTAMP
);

INSERT INTO customer_orders_cleaned
SELECT order_id, customer_id, pizza_id,
	CASE WHEN exclusions LIKE 'null' OR exclusions IS NULL THEN ''
    ELSE exclusions END AS exclusions,
    CASE WHEN extras LIKE 'null' OR extras IS NULL THEN ''
    ELSE extras END AS extras,
    order_time
FROM customer_orders;

-- Clean table: runner_orders
CREATE TABLE runner_orders_cleaned (
  order_id INTEGER,
  runner_id INTEGER,
  pickup_time VARCHAR(19),
  distance VARCHAR(7),
  duration VARCHAR(10),
  cancellation VARCHAR(23)
);

INSERT INTO runner_orders_cleaned
SELECT order_id, runner_id, 
	CASE WHEN pickup_time LIKE 'null' THEN ''
    ELSE pickup_time END AS pickup_time,
    CASE WHEN distance LIKE 'null' THEN ''
		 WHEN distance LIKE '%km' THEN TRIM('km' FROM distance) 
    ELSE distance END AS distance,
    CASE WHEN duration LIKE 'null' THEN ''
		 WHEN duration LIKE '%mins' THEN TRIM('mins' FROM duration)
         WHEN duration LIKE '%minute' THEN TRIM('minute' FROM duration)
         WHEN duration LIKE '%minutes' THEN TRIM('minutes' FROM duration)
    ELSE duration END AS duration,
    CASE WHEN cancellation IS NULL OR cancellation LIKE 'null' THEN ''
    ELSE cancellation END AS cancellation
FROM runner_orders;

ALTER TABLE runner_orders_cleaned
MODIFY pickup_time DATETIME,
MODIFY distance FLOAT,
MODIFY duration INTEGER;

-- Clean table: pizza_recipes
CREATE TABLE pizza_recipes_cleaned (
	pizza_id INTEGER,
    topping INTEGER
);
INSERT INTO pizza_recipes_cleaned 
	(pizza_id, topping)
VALUES
	(1, 1),
    (1, 2),
    (1, 3),
    (1, 4),
    (1, 5),
    (1, 6),
    (1, 8),
    (1, 10),
    (2, 4),
    (2, 6),
    (2, 7),
    (2, 9),
    (2, 11),
    (2, 12);
-- DATA CLEANING --

/* -------------------------------------
   Case Study Questions A: Pizza Metrics
   -------------------------------------*/
-- 1. How many pizzas were ordered?
SELECT COUNT(*) AS NumPizzasOrdered
FROM customer_orders_cleaned;

-- 2. How many unique customer orders were made?
SELECT COUNT(DISTINCT order_id) AS UniqueOrders
FROM customer_orders_cleaned;

-- 3. How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(order_id) AS SuccessfulOrders
FROM runner_orders_cleaned
WHERE cancellation = ''
GROUP BY runner_id;

-- 4. How many of each type of pizza was delivered?
SELECT pizza_id, COUNT(*) AS QtyDelivered
FROM customer_orders_cleaned AS c LEFT JOIN runner_orders_cleaned AS r ON c.order_id = r.order_id
WHERE cancellation = ''
GROUP BY pizza_id;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?
SELECT customer_id, pizza_name, COUNT(pizza_name) AS QtyOrdered
FROM pizza_names NATURAL JOIN customer_orders_cleaned
GROUP BY customer_id, pizza_name;

-- 6. What was the maximum number of pizzas delivered in a single order?
SELECT COUNT(pizza_id) AS MaxNumPizzaDelivered
FROM customer_orders_cleaned NATURAL JOIN runner_orders_cleaned 
WHERE cancellation = ''
GROUP BY order_id
ORDER BY MaxNumPizzaDelivered DESC
LIMIT 1;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT customer_id,
	SUM(CASE WHEN exclusions != '' OR extras != '' THEN 1
		ELSE 0 END) AS with_changes,
	SUM(CASE WHEN exclusions = '' AND extras = '' THEN 1
		ELSE 0 END) AS no_changes
FROM customer_orders_cleaned NATURAL JOIN runner_orders_cleaned
GROUP BY customer_id;

-- 8. How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(*) AS NumPizzas
FROM customer_orders_cleaned NATURAL JOIN runner_orders_cleaned
WHERE distance != 0 AND exclusions != '' AND extras != '';

-- 9. What was the total volume of pizzas ordered for each hour of the day?
SELECT HOUR(order_time) AS order_by_hour, COUNT(pizza_id) AS QtyOrdered
FROM customer_orders_cleaned
GROUP BY HOUR(order_time)
ORDER BY HOUR(order_time);

-- 10. What was the volume of orders for each day of the week?
SELECT DAYOFWEEK(order_time) AS order_by_day_of_week, COUNT(pizza_id) AS QtyOrdered
FROM customer_orders_cleaned
GROUP BY DAYOFWEEK(order_time)
ORDER BY DAYOFWEEK(order_time);

/* ------------------------------------------------------
   Case Study Questions B: Runner and Customer Experience
   ------------------------------------------------------*/
-- 1. How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT week_starting, COUNT(runner_id) AS signups
FROM (
	 SELECT runner_id, registration_date, registration_date - ((registration_date - DATE('2021-01-01')) % 7)  AS week_starting
	 FROM runners
	 ) AS runner_registration
GROUP BY week_starting
ORDER BY week_starting;

-- 2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT runner_id, ROUND(AVG(MINUTE(TimeTaken)), 0) AS AvgTimeTaken
FROM (
	 SELECT runner_id, TIMEDIFF(order_time, pickup_time) AS TimeTaken
     FROM customer_orders_cleaned NATURAL JOIN runner_orders_cleaned
     WHERE duration != 0
     ) AS runner_time_taken
GROUP BY runner_id;

-- 3. Is there any relationship between the number of pizzas and how long the order takes to prepare?
SELECT qty_ordered, ROUND(AVG(MINUTE(prep_time)), 0) AS avg_prep_time, ROUND(ROUND(AVG(MINUTE(prep_time)), 0) / qty_ordered, 0) AS avg_prep_time_for_one_pizza
FROM (
	 SELECT order_id, COUNT(order_id) AS qty_ordered, TIMEDIFF(order_time, pickup_time) AS prep_time
     FROM customer_orders_cleaned NATURAL JOIN runner_orders_cleaned
     WHERE duration != 0
     GROUP BY order_id, order_time, pickup_time
     ) AS pizza_summary
GROUP BY qty_ordered;

-- 4. What was the average distance travelled for each customer?
SELECT customer_id, ROUND(AVG(distance), 2) AS avg_distance
FROM customer_orders_cleaned AS c RIGHT JOIN runner_orders_cleaned AS r ON c.order_id = r.order_id
WHERE distance != 0
GROUP BY customer_id;

-- 5. What was the difference between the longest and shortest delivery times for all orders?
SELECT MAX(duration) - MIN(duration) AS duration_difference
FROM runner_orders_cleaned
WHERE duration != 0;

-- 6. What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT runner_id, order_id, ROUND(distance / (duration / 60), 2) AS avg_km_per_hour
FROM runner_orders_cleaned
WHERE distance != 0
GROUP BY runner_id, order_id, distance, duration
ORDER BY runner_id, avg_km_per_hour;

-- 7. What is the successful delivery percentage for each runner?
SELECT runner_id, CONCAT(ROUND((COUNT(CASE WHEN distance != 0 THEN 1 ELSE NULL END) / COUNT(*)) * 100, 2), '%') AS successful_delivery_percentage 
FROM runner_orders_cleaned
GROUP BY runner_id;

/* -----------------------------------------------
   Case Study Questions C: Ingredient Optimisation
   -----------------------------------------------*/
-- 1. What are the standard ingredients for each pizza?
SELECT pizza_name, topping_name
FROM pizza_names NATURAL JOIN pizza_recipes_cleaned 
	INNER JOIN pizza_toppings ON pizza_recipes_cleaned.topping = pizza_toppings.topping_id
ORDER BY pizza_name, topping_name;

-- 2. What was the most commonly added extra?
SELECT topping_name
FROM customer_orders_cleaned INNER JOIN pizza_toppings ON customer_orders_cleaned.extras = pizza_toppings.topping_id
GROUP BY extras, topping_name
ORDER BY COUNT(*) DESC
LIMIT 1;

-- 3. What was the most common exclusion?
SELECT topping_name
FROM customer_orders_cleaned INNER JOIN pizza_toppings ON customer_orders_cleaned.exclusions = pizza_toppings.topping_id
GROUP BY exclusions, topping_name
ORDER BY COUNT(*) DESC
LIMIT 1;

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following: Meat Lovers / Meat Lovers - Exclude Beef / Meat Lovers - Extra Bacon / Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
SELECT order_id, c.pizza_id, pizza_name, exclusions, extras,
	CASE WHEN exclusions = '4' AND extras = '' THEN CONCAT(pizza_name, ' - Exclude Cheese')
		 WHEN exclusions = '' AND extras = '1' THEN CONCAT(pizza_name, ' - Extra Bacon')
		 WHEN exclusions = '4' AND extras = '1, 5' THEN CONCAT(pizza_name, ' - Exclude Cheese - Extra Bacon, Chicken')
		 WHEN exclusions = '2, 6' AND extras = '1, 4' THEN CONCAT(pizza_name, ' - Exclude BBQ Sauce, Mushrooms - Extra Bacon, Cheese')
    ELSE pizza_name END AS order_item
FROM customer_orders_cleaned AS c INNER JOIN pizza_names AS p ON c.pizza_id = p.pizza_id;

-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients. For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
CREATE TEMPORARY TABLE order_ingredients
SELECT order_id, pizza_id, exclusions, extras, 
	CASE WHEN exclusions = '2, 6' THEN 'BBQ Sauce, Mushrooms'
    ELSE excluded_topping_temp END AS excluded_topping,
    CASE WHEN extras = '1, 4' THEN 'Bacon, Cheese'
		 WHEN extras = '1, 5' THEN 'Bacon, Chicken'
    ELSE extra_topping_temp END AS extra_topping,
    CASE WHEN pizza_id = 1 THEN 'Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Peperoni, Salami'
    ELSE 'Cheese, Mushrooms, Onions, Peppers, Tomato Sauce, Tomatoes' END AS ingredients
FROM (
	 SELECT order_id, pizza_id, exclusions, extras, p.topping_name AS excluded_topping_temp, pp.topping_name AS extra_topping_temp
	 FROM customer_orders_cleaned AS c LEFT JOIN pizza_toppings AS p ON c.exclusions = p.topping_id
	 LEFT JOIN pizza_toppings AS pp ON c.extras = pp.topping_id
     ) AS draft_order_ingredients;

SELECT order_id, pizza_id, exclusions, extras, excluded_topping, extra_topping,
	CASE WHEN exclusions = '2, 6' THEN REPLACE(REPLACE(ingredients, 'BBQ Sauce,', ''), 'Mushrooms,', '')
		 WHEN exclusions = '4' THEN REPLACE(ingredients, 'Cheese,', '')
         WHEN extras = '1, 4' THEN REPLACE(REPLACE(ingredients, 'Bacon', '2xBacon'), 'Cheese', '2xCheese')
         WHEN extras = '1, 5' THEN REPLACE(REPLACE(ingredients, 'Bacon', '2xBacon'), 'Chicken', '2xChicken')
         WHEN extras = '1' AND pizza_id = 1 THEN REPLACE(ingredients, 'Bacon', '2xBacon')
         WHEN extras = '1' AND pizza_id = 2 THEN CONCAT('Bacon, ', ingredients)
	ELSE ingredients END AS ingredients
FROM order_ingredients
ORDER BY order_id, pizza_id;

-- 6. What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
DROP TABLE IF EXISTS total_ingredients;
CREATE TEMPORARY TABLE total_ingredients
SELECT c.order_id, c.pizza_id, p.topping, t.topping_name, c.exclusions
FROM customer_orders_cleaned AS c NATURAL JOIN runner_orders_cleaned
	INNER JOIN pizza_recipes_cleaned AS p ON c.pizza_id = p.pizza_id
	INNER JOIN pizza_toppings AS t ON p.topping = t.topping_id
WHERE cancellation = '';

DELETE FROM total_ingredients WHERE order_id = 4 AND pizza_id = 1 AND topping = 4;
DELETE FROM total_ingredients WHERE order_id = 4 AND pizza_id = 2 AND topping = 4;
DELETE FROM total_ingredients WHERE order_id = 9 AND pizza_id = 1 AND topping = 4;
DELETE FROM total_ingredients WHERE order_id = 10 AND pizza_id = 1 AND topping = 2 AND exclusions = '2, 6';
DELETE FROM total_ingredients WHERE order_id = 10 AND pizza_id = 1 AND topping = 6 AND exclusions = '2, 6';
INSERT INTO total_ingredients
VALUES
	(5,1,1,'Bacon',NULL),
    (7,2,1,'Bacon',NULL),
    (9,1,1,'Bacon',NULL),
    (9,1,5,'Chicken',NULL),
    (10,1,1,'Chicken',NULL),
    (10,1,4,'Cheese',NULL);

SELECT topping, topping_name, COUNT(*) AS qty
FROM total_ingredients
GROUP BY topping, topping_name
ORDER BY qty DESC;

/* -------------------------------------------
   Case Study Questions D: Pricing and Ratings
   -------------------------------------------*/
-- 1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
SELECT SUM(CASE WHEN pizza_id = 1 THEN 12 ELSE 10 END) AS earning
FROM (
	  SELECT order_id, pizza_id
      FROM customer_orders_cleaned NATURAL JOIN runner_orders_cleaned
      WHERE cancellation = ''
      ) AS orders;

-- 2. What if there was an additional $1 charge for any pizza extras? (E.g. Add cheese is $1 extra)
SELECT SUM(
	CASE WHEN pizza_id = 1 AND (extras = '1, 5' OR extras = '1, 4') THEN 14 
		 WHEN pizza_id = 1 AND extras = '1' THEN 13
         WHEN pizza_id = 1 AND extras = '' THEN 12
         WHEN pizza_id = 2 AND extras = '1' THEN 11
    ELSE 10 END) AS earning
FROM (
	  SELECT order_id, pizza_id, extras
      FROM customer_orders_cleaned NATURAL JOIN runner_orders_cleaned
      WHERE cancellation = ''
      ) AS orders;

-- 3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
CREATE TABLE ratings (
	order_id INTEGER,
    rating TINYINT
);
INSERT INTO ratings
VALUES
	(1, 4),
    (2, 5),
    (3, 4),
    (4, 3),
    (5, 5),
    (7, 4),
    (8, 4),
    (10, 2);
SELECT * FROM ratings;

-- 4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
SELECT customer_id, 
	   c.order_id, 
       runner_id, 
       rating, 
       order_time, 
       pickup_time, 
       ROUND(MINUTE(TIMEDIFF(order_time, pickup_time)), 0) AS timediff_order_pickup, 
       duration, 
       ROUND(distance / (duration / 60), 2) AS avg_speed, 
       COUNT(pizza_id) AS total_pizza
FROM customer_orders_cleaned AS c NATURAL JOIN runner_orders_cleaned
	INNER JOIN ratings ON c.order_id = ratings.order_id
WHERE cancellation = ''
GROUP BY customer_id, c.order_id, runner_id, rating, order_time, pickup_time, duration, avg_speed
ORDER BY customer_id;

-- 5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?
SELECT ROUND(SUM(CASE WHEN pizza_id = 1 THEN 12 ELSE 10 END) - SUM(distance) * 0.3, 2) AS earning_left
FROM (
	  SELECT order_id, pizza_id, distance
      FROM customer_orders_cleaned NATURAL JOIN runner_orders_cleaned
      WHERE cancellation = ''
      ) AS orders;

-- Bonus Question: If Danny wants to expand his range of pizzas - how would this impact the existing data design? Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
INSERT INTO pizza_names VALUES (3, 'Supreme');

INSERT INTO pizza_recipes_cleaned VALUES
	(3,1),
    (3,2),
    (3,3),
    (3,4),
    (3,5),
    (3,6),
    (3,7),
    (3,8),
    (3,9),
    (3,10);
    
SELECT * FROM pizza_names;
SELECT * FROM pizza_recipes_cleaned;