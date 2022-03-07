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



-- 5. Which item was the most popular for each customer?
-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

-- Example Query:

