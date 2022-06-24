-- SCHEMA --
CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
-- SCHEMA --

/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id, SUM(price) AS TotalSpent
FROM sales NATURAL JOIN menu
GROUP BY customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS DaysVisited
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
SELECT customer_id, product_name
FROM (
	SELECT customer_id, order_date, product_id, product_name, DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS order_rank 
    FROM sales NATURAL JOIN menu
    ) AS order_ranked
WHERE order_rank = 1
GROUP BY customer_id, product_name;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name, COUNT(*) AS NumberOfTimesPurchased
FROM sales NATURAL JOIN menu
GROUP BY product_name
ORDER BY NumberOfTimesPurchased DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?
SELECT customer_id, product_name, order_count
FROM (
	 SELECT customer_id, product_name, COUNT(product_id) AS order_count, DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY COUNT(product_id) DESC) as item_rank
     FROM sales NATURAL JOIN menu
     GROUP BY customer_id, product_name
) AS order_count_table
WHERE item_rank = 1;

-- 6. Which item was purchased first by the customer after they became a member?
SELECT customer_id, product_name
FROM (
	SELECT sales.customer_id, product_name, DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS order_rank
    FROM sales NATURAL JOIN menu 
		INNER JOIN members ON sales.customer_id = members.customer_id
	WHERE order_date >= join_date
    ) AS member_order
WHERE order_rank = 1;

-- 7. Which item was purchased just before the customer became a member?
SELECT customer_id, product_name
FROM (
	SELECT sales.customer_id, product_name, DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS order_rank
    FROM sales NATURAL JOIN menu 
		INNER JOIN members ON sales.customer_id = members.customer_id
	WHERE order_date < join_date
    ) AS member_order
WHERE order_rank = 1;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT sales.customer_id, COUNT(product_name) AS TotalItemsOrdered, SUM(price) AS TotalAmountSpent
FROM sales NATURAL JOIN menu 
	INNER JOIN members ON sales.customer_id = members.customer_id
WHERE order_date < join_date
GROUP BY sales.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT customer_id, SUM(points) AS TotalPoints
FROM (
	  SELECT *,
		CASE WHEN product_name = 'sushi' THEN price*20
        ELSE price*10 END AS points
	  FROM sales NATURAL JOIN menu
      ) AS customer_points
GROUP BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT customer_id, SUM(points) AS TotalPoints
FROM (
	  SELECT sales.customer_id,
		CASE WHEN product_name != 'sushi' AND (order_date < join_date OR order_date > join_date + 6) THEN price*10
        ELSE price*20 END AS points
	  FROM sales NATURAL JOIN menu
		INNER JOIN members ON sales.customer_id = members.customer_id
      ) AS customer_points
GROUP BY customer_id;

-- BONUS QUESTION: Join All The Things
SELECT sales.customer_id, sales.order_date, menu.product_name, menu.price,
	CASE WHEN order_date >= join_date THEN 'Y'
    ELSE 'N' END AS member
FROM sales NATURAL JOIN menu
	LEFT JOIN members ON sales.customer_id = members.customer_id
ORDER BY sales.customer_id, sales.order_date;

-- BONUS QUESTION: Rank All The Things
SELECT *,
	CASE WHEN member = 'N' THEN null
    ELSE DENSE_RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date) END AS ranking
FROM (
	SELECT sales.customer_id, sales.order_date, menu.product_name, menu.price,
		CASE WHEN order_date >= join_date THEN 'Y'
		ELSE 'N' END AS member
	FROM sales NATURAL JOIN menu
		LEFT JOIN members ON sales.customer_id = members.customer_id
	ORDER BY sales.customer_id, sales.order_date
    ) AS join_all;
	