#What is the total amount each customer spent at the restaurant?

SELECT s.customer_id customer, sum(m.price) total_spend
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY customer_id;

#How many days has each customer visited the restaurant?

SELECT customer_id customer, count(DISTINCT order_date) no_of_days
FROM sales
GROUP BY customer_id;

#What was the first item from the menu purchased by each customer?

WITH t1 AS (SELECT s.customer_id customer, m.product_name product,
ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) first_order
FROM sales s
JOIN menu m
ON s.product_id = m.product_id)

SELECT customer, product
FROM  t1
WHERE first_order = 1;

#What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT m.product_name, COUNT(s.product_id) no_of_purchases
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY 1
ORDER BY COUNT(s.product_id) DESC
LIMIT 1;

#Which item was the most popular for each customer?

WITH t2 AS (SELECT s.customer_id customer, m.product_name, COUNT(s.product_id) no_of_purchases, 
DENSE_RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) order_rank
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY 1,2)

SELECT customer, product_name, no_of_purchases
FROM t2
WHERE order_rank = 1;

#Which item was purchased first by the customer after they became a member?

SELECT customer_id, product_name
FROM (SELECT s.customer_id, s.product_id, ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY order_date) order_rank
FROM sales s
JOIN members mem
ON s.customer_id = mem.customer_id
WHERE s.order_date >= mem.join_date) t1
JOIN menu m
ON t1.product_id = m.product_id
WHERE order_rank = 1
ORDER BY 1;

#Which item was purchased just before the customer became a member?

SELECT customer_id, product_name
FROM (SELECT s.customer_id, s.product_id, ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date DESC) order_rank
FROM sales s
JOIN members mem
ON s.customer_id = mem.customer_id
WHERE s.order_date < mem.join_date) t1
JOIN menu m
ON t1.product_id = m.product_id
WHERE order_rank = 1
ORDER BY 1;

#What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id customer, COUNT(s.product_id) purchases, SUM(m.price) amt_spent
FROM sales s
JOIN members mem
ON s.customer_id = mem.customer_id
JOIN menu m
ON s.product_id = m.product_id
WHERE s.order_date < mem.join_date
GROUP BY 1
ORDER BY 1;

#If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT customer_id customer,
SUM(CASE WHEN m.product_name = 'sushi' THEN price*20 ELSE price*10 END) points
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY 1;

#In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT s.customer_id, 
SUM(CASE 
WHEN s.order_date BETWEEN mem.join_date AND DATE_ADD(mem.join_date, INTERVAL 6 DAY) THEN m.price*20
WHEN m.product_name ='sushi' THEN m.price*20
ELSE price*10
END) points
FROM sales s
JOIN members mem
ON s.customer_id = mem.customer_id
JOIN menu m
ON s.product_id = m.product_id
WHERE month(s.order_date) = 1
GROUP BY 1;

