--
/*
Project: E-Commerce Business Insights & Customer Behavior Analysis(Olist Dataset)
Author: Harish Kumar


Objective:
Analyze customer behavior, revenue trends, and product performance.

Tables Used:
- customers
- orders
- order_items
- products
- order_payments
- product_category_name_translation
*/

-- =============================================
-- 1.How many orders has the platform processed?
-- =============================================


SELECT
	COUNT(DISTINCT order_id) AS total_orders
FROM orders;



-- ====================================
-- 2.What is the total money generated?
-- =====================================


SELECT
	SUM(op.payment_value) AS total_revenue
FROM order_payments op	
JOIN orders o ON op.order_id = o.order_id
WHERE o.order_status = 'delivered'

-- ===========================================
-- 3.How much does a customer spend per order?
-- ===========================================


SELECT 
ROUND(AVG(order_revenue),2) AS average_order_value
FROM(
	SELECT op.order_id,SUM(op.payment_value) AS order_revenue
    FROM order_payments op
    JOIN orders o ON op.order_id = o.order_id
	WHERE o.order_status = 'delivered'
    GROUP BY op.order_id
)t;



-- ===============================
-- 4.How big is the customer base?
-- ================================


SELECT COUNT(DISTINCT customer_unique_id) AS total_customers
FROM customers


-- =====================================================
-- 5.How is demand changing over time(monthly analysis)?
-- ======================================================

SELECT DATE_TRUNC('month',order_purchase_timestamp) AS months,
	COUNT(DISTINCT order_id) AS orders_per_month
FROM orders
WHERE order_status = 'delivered'
GROUP BY months
ORDER BY months DESC;


-- ============================================
-- 6.Are users coming back or just trying once?
-- =============================================

SELECT customer_status,
	   COUNT(customer_unique_id) AS customer_count,
	   ROUND(100 * COUNT(customer_unique_id)/SUM(COUNT(customer_unique_id))OVER(),2) AS percentage
FROM(
SELECT c.customer_unique_id,
	   COUNT(o.order_id) AS order_count,
	   CASE
	       WHEN COUNT(o.order_id)>1 
		   THEN 'Returning' 
		   ELSE 'New' 
		   END AS customer_status
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
)t
GROUP BY customer_status; 


-- ======================================
-- 7.Who are the most valuable customers?
-- =======================================


SELECT *
FROM
(SELECT c.customer_unique_id,
	   SUM(op.payment_value) AS total_revenue,
	   RANK() OVER(ORDER BY SUM(op.payment_value) DESC) AS rank
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_payments op ON op.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
ORDER BY total_revenue DESC
)t
WHERE rank <=10


-- ================================================================
-- 8.Who signed up but never bought? ie,,Customers with no purchase
-- =================================================================

SELECT DISTINCT customer_unique_id 
FROM customers 
WHERE customer_unique_id IS NOT NULL 
AND customer_unique_id NOT IN
(
SELECT c2.customer_unique_id 
FROM orders o 
JOIN customers c2 ON o.customer_id = c2.customer_id 
WHERE o.order_status = 'delivered');

-- ==================================================
-- 9.How much revenue each customer brings over time?
-- ===================================================

SELECT c.customer_unique_id,
       SUM(op.payment_value) as revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_payments op ON o.order_id = op.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_unique_id
ORDER BY revenue DESC


-- =====================================
-- 10.Which products drive sales volume?
-- ======================================

SELECT pc.product_category_name_english,
       COUNT(oi.order_id) AS total_units_sold
FROM product_category_name_translation pc
JOIN products p ON pc.product_category_name = p.product_category_name
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered' 
GROUP BY pc.product_category_name_english
ORDER BY total_units_sold DESC


-- ==========================
-- 11.Is the business growing?
-- ==========================

WITH payments_per_order AS(
SELECT order_id,
       SUM(payment_value) as revenue
FROM order_payments
GROUP BY order_id
)
SELECT DATE_TRUNC('month',o.order_purchase_timestamp) AS months,
       SUM(op.revenue) AS revenue,
	   COUNT(DISTINCT o.order_id) AS order_count
FROM orders o
JOIN payments_per_order op ON o.order_id = op.order_id
WHERE o.order_status = 'delivered'
GROUP BY months
ORDER BY months


-- ==================================================
-- 12.Which product categories generate most revenue?
-- ===================================================

SELECT pt.product_category_name_english,
       SUM(oi.price + oi.freight_value) as revenue
FROM product_category_name_translation pt
JOIN products p ON pt.product_category_name = p.product_category_name
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id  = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY pt.product_category_name_english
ORDER BY revenue DESC


-- ==============================
-- 13.Which city perform best?
-- ===============================

WITH payment_per_order AS (
    SELECT 
        order_id,
        SUM(payment_value) AS total_payment
    FROM order_payments
    GROUP BY order_id
)

SELECT c.customer_city,
	   SUM(op.total_payment) AS revenue
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN payment_per_order op ON o.order_id = op.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_city
ORDER BY revenue DESC


-- ===============================
-- 14.Which day has highest demand?
-- ================================

SELECT TO_CHAR(order_purchase_timestamp,'day')as week_day 
       ,COUNT(order_id) as order_count
FROM orders
WHERE order_status = 'delivered'
GROUP BY week_day
ORDER BY order_count DESC


-- ============================
-- 15. How loyal are customers?
-- =============================


SELECT ROUND(100* SUM(CASE WHEN order_count > 1 THEN 1 ELSE 0 END)
       /COUNT(customer_unique_id),2)  AS repeat_purchase_rate
FROM
	(SELECT c.customer_unique_id AS customer_unique_id,
            COUNT(c.customer_id) AS order_count
	FROM customers c
	JOIN orders o ON c.customer_id = o.customer_id
	WHERE o.order_status = 'delivered'
	GROUP BY c.customer_unique_id
)t;

-- ==================================
-- 16.How frequently customers return?
-- ===================================

WITH order_gabs AS
(
	SELECT c.customer_unique_id,
	   o.order_purchase_timestamp,
	   LAG(o.order_purchase_timestamp)OVER(
	   PARTITION BY c.customer_unique_id
	   ORDER BY o.order_purchase_timestamp
	   ) AS previous_purchase_date
	FROM customers c
	JOIN orders o ON c.customer_id = o.customer_id
	WHERE o.order_status = 'delivered'
),
date_diff AS
(
	SELECT customer_unique_id,
	       (order_purchase_timestamp::date)-(previous_purchase_date::date)AS gapdays
	FROM order_gabs
	WHERE previous_purchase_date IS NOT NULL
)
SELECT ROUND(AVG(gapdays),2) AS avg_days_between_purchases 
FROM date_diff


-- ==================================
-- 17.Which customers stopped buying?
-- ===================================

WITH last_order AS 
(	
	SELECT c.customer_unique_id,
	       MAX(o.order_purchase_timestamp) AS last_purchase_date
	FROM customers c
	JOIN orders o ON c.customer_id = o.customer_id
	WHERE o.order_status = 'delivered'
	GROUP BY c.customer_unique_id
),
max_order_purchase_date AS
(	
	SELECT MAX(order_purchase_timestamp) AS max_date
	FROM orders
	WHERE order_status = 'delivered'
)
SELECT customer_unique_id,
       last_purchase_date
FROM last_order,max_order_purchase_date
WHERE last_purchase_date < (max_date - INTERVAL '100 days')



-- =============================
-- 18. How fast are deliveries?
-- =============================

WITH order_delivery_time AS
(SELECT order_id,
       EXTRACT(EPOCH FROM 
	   (order_delivered_customer_date - order_purchase_timestamp))/86400 AS delivery_time
FROM orders
WHERE order_status = 'delivered' AND 
      order_delivered_customer_date IS NOT NULL
	  )
SELECT ROUND(AVG(delivery_time),2) AS average_delivery_time
FROM order_delivery_time


-- ========================================
-- 19.Are we meeting delivery expectations?
-- =========================================

SELECT 
	  ROUND(100.0 * COUNT(*) 
	  FILTER (
	         WHERE order_delivered_customer_date > order_estimated_delivery_date
			 )
	  / COUNT(*),2) AS late_delivery_percentage
FROM orders
WHERE order_status = 'delivered'
	  AND order_delivered_customer_date IS NOT NULL
	  AND order_estimated_delivery_date IS NOT NULL



-- ==============================================
-- 20.How many orders are cancelled vs delivered?
-- ===============================================

SELECT order_status,
       COUNT(*) AS order_count,
	   ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER(),2) AS percentage
FROM orders
WHERE order_status IN ('delivered','canceled')
GROUP BY order_status
ORDER BY order_count DESC


-- ===================================
-- 21. Which payment method dominates?
-- ====================================

SELECT p.payment_type,
       COUNT(DISTINCT p.order_id) AS order_count
FROM order_payments p
JOIN orders o ON p.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.payment_type
ORDER BY order_count DESC


-- ==========================================================
-- 22.Are customers making high-value or low-value purchases?
-- ===========================================================


WITH order_value AS
(
	SELECT o.order_id,
		   SUM(op.payment_value) AS order_value 
	FROM orders o
	JOIN order_payments op ON o.order_id = op.order_id
	WHERE o.order_status = 'delivered'
	GROUP BY o.order_id
),
order_value_average AS
(
	SELECT AVG(order_value) AS average_order_value
	FROM order_value
)
SELECT CASE
			WHEN order_value > average_order_value THEN 'High Value'
			ELSE 'Low Value'
			END AS category,
		COUNT(*) AS order_count
FROM order_value,order_value_average
GROUP BY category;

       
