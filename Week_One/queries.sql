/* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?
SELECT sales.customer_id, SUM(menu.price) FROM dannys_diner.sales
JOIN dannys_diner.menu
ON sales.product_id = menu.product_id
GROUP BY sales.customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT sales.customer_id, COUNT(DISTINCT sales.order_date) FROM dannys_diner.sales
GROUP BY sales.customer_id

-- 3. What was the first item from the menu purchased by each customer?
WITH first_sales AS 
(
  SELECT customer_id, order_date, product_name,
  DENSE_RANK() 
  OVER 
  (PARTITION BY s.customer_id 
   ORDER BY s.order_date) AS rank
  FROM dannys_diner.sales AS s
  JOIN dannys_diner.menu AS m
  ON m.product_id = s.product_id
  )

SELECT customer_id, order_date, product_name
FROM first_sales
WHERE rank = 1
GROUP BY customer_id, order_date, product_name;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

WITH counts AS (
SELECT COUNT(s.product_id), m.product_name
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu AS m
ON m.product_id = s.product_id
GROUP BY m.product_name)
-- creating a table here that counts the amount of orders each product has
SELECT product_name, MAX(count) AS most_orders -- creating a new column name 'most_orders'
FROM counts
WHERE count=(
  SELECT MAX(count) FROM counts) -- only returning results that match the column value of the max
GROUP BY counts.product_name
 
-- OR

SELECT TOP 1 (COUNT(s.product_id)) AS most_purchased, product_name
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu AS m
   ON s.product_id = m.product_id
GROUP BY s.product_id, product_name
ORDER BY most_purchased DESC;

-- this method is more efficient with less lines of code. 


-- 5. Which item was the most popular for each customer?

WITH most_popular_1 AS 
-- creating the temporary table 'most_popular_1' --
( 
SELECT COUNT(s.product_id) AS max, m.product_name, s.customer_id, 
  DENSE_RANK()
  OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS rank
  -- creating a rank order of the dishes ordered by customers, by quantity that they were ordered --
  -- the order by count DESC puts them in descending order, the dense_rank ranks them accordingly--
FROM dannys_diner.sales AS s
JOIN dannys_diner.menu AS m
ON m.product_id = s.product_id
GROUP BY m.product_name, s.customer_id
)
-- temporary table helps select function below-- 
SELECT customer_id, product_name AS most_popular_dish, max AS quantity_ordered FROM most_popular_1
WHERE rank = 1;
-- WHERE rank = 1 only returns the top ranked orders

-- 6. Which item was purchased first by the customer after they became a member?

WITH member_sales AS 
(
   SELECT s.customer_id, m.join_date, s.order_date, s.product_id,
      DENSE_RANK() OVER(PARTITION BY s.customer_id
      ORDER BY s.order_date) AS rank
   FROM dannys_diner.sales AS s
   JOIN dannys_diner.members AS m
      ON s.customer_id = m.customer_id
   WHERE s.order_date >= m.join_date
)
-- the above ranks the orders by the date that they were ordered, and the Where statement filters out the orders that
-- existed only after the individual became a member. We also see the JOIN statement adding the member join date

SELECT customer_id, order_date, product_name FROM member_sales
JOIN dannys_diner.menu as m
ON m.product_id = member_sales.product_id
WHERE rank = 1
GROUP BY customer_id, order_date, product_name;

-- Here we filter the desired columns, we add the JOIN so we can see the product name instead of the ID in the answer.
-- The where statement insures that we are only getting the first item that the individual ordered.

-- 7. Which item was purchased just before the customer became a member?

WITH member_sales AS 
(
   SELECT s.customer_id, m.join_date, s.order_date, s.product_id,
      DENSE_RANK() OVER(PARTITION BY s.customer_id
      ORDER BY s.order_date DESC) AS rank
   FROM dannys_diner.sales AS s
   JOIN dannys_diner.members AS m
      ON s.customer_id = m.customer_id
   WHERE s.order_date < m.join_date
)

-- This question is similar to the previous one. Instead, we order the date and set DESC to go from the most recent date backwards.
-- We change the WHERE to only include dates that happened prior to the individual becoming a member.

SELECT customer_id, order_date, product_name FROM member_sales
JOIN dannys_diner.menu as m
ON m.product_id = member_sales.product_id
WHERE rank = 1
GROUP BY customer_id, order_date, product_name;

-- this portion is the same as the question before.

-- 8. What is the total items and amount spent for each member before they became a member?

WITH member_sales AS 
(
   SELECT s.customer_id, m.join_date, s.order_date, s.product_id,
      DENSE_RANK() OVER(PARTITION BY s.customer_id
      ORDER BY s.order_date ) AS rank
   FROM dannys_diner.sales AS s
   JOIN dannys_diner.members AS m
      ON s.customer_id = m.customer_id
   WHERE s.order_date < m.join_date
)

-- This is portion is the same as the previous question. We're creating a temporary table that only displace purchases prior to membership.

SELECT customer_id, SUM(price) as total_spent_before_member, COUNT(member_sales.product_id) as total_items_purchased FROM member_sales
JOIN dannys_diner.menu as m
ON m.product_id = member_sales.product_id
GROUP BY customer_id;

-- here we are using the sum function on the price column of the menu table, this returns the total of the purchase.

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH point_totals AS 
(
   SELECT s.customer_id, s.order_date, s.product_id,
  CASE
  WHEN s.product_id = 1
  THEN price * 20
  ELSE price * 10 
  END AS points
   FROM dannys_diner.sales AS s
   JOIN dannys_diner.menu AS m
      ON s.product_id = m.product_id
)

-- this creates a temporary table that displays the total orders along with how many points each order is worth.
-- The logic statement states that product_id = 1, or sushi, is equal to 20 points per dollar, or price. The others are worth 10.

SELECT customer_id, SUM(points) as total_points FROM point_totals
GROUP BY customer_id;

-- this simple sum fuction creates a new column called total_points, summing everything in each customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH member_sales AS 
(
  SELECT s.customer_id, m.join_date, s.order_date, s.product_id,
  CASE
  WHEN s.order_date - m.join_date < 7
  THEN menu.price * 20
  WHEN s.product_id = 1
  THEN menu.price * 20
  ELSE menu.price * 10
  END AS points
   FROM dannys_diner.sales AS s
   JOIN dannys_diner.members AS m
      ON s.customer_id = m.customer_id
  JOIN dannys_diner.menu
  	  ON menu.product_id = s.product_id
   WHERE s.order_date >= m.join_date
)

SELECT customer_id, SUM(points) FROM member_sales
WHERE order_date < '2021-02-01T00:00:00.000Z'
GROUP BY customer_id;
