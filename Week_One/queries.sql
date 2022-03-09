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

SELECT customer_id, order_date, product_name FROM member_sales
JOIN dannys_diner.menu as m
ON m.product_id = member_sales.product_id
WHERE rank = 1
GROUP BY customer_id, order_date, product_name;


-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- Example Query:

