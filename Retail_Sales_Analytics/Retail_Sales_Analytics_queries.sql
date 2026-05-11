use Retail_Sales_Analytics;
-- ============================================================
-- PHASE 1 — SCHEMA ARCHITECT
-- Topics: DDL Statements (CREATE, ALTER, DROP) | DML Statements
--         (INSERT, UPDATE, DELETE) | Modifying Columns
-- ============================================================
 
-- ------------------------------------------------------------
-- Task 1.1 — DDL: Design a New Table
-- ------------------------------------------------------------
/*
   Business Requirement:
   The business wants to track product reviews. Create a
   product_reviews table with the following rules:
   - Linked to exactly one customer and one product (FK enforced)
   - rating: mandatory INTEGER, values 1–5 only (CHECK constraint)
   - review_text: optional (nullable)
   - review_date: mandatory
   - A customer can review the same product only once
     (composite UNIQUE on customer_id, product_id)
   - verified_purchase: TINYINT(1), defaults to 0 (FALSE)
*/

create table product_reviews( 
review_id INT primary Key,
customer_id INT ,
product_id INT ,
rating INT NOT NULL check (rating between 1 and 5),
review_text varchar(100),
review_date date NOT NULL,
verified_purchase tinyint(1) default 0,
UNIQUE (customer_id, product_id),
foreign key(customer_id) REFERENCES Customers(customer_id),
foreign key(product_id) REFERENCES Products(product_id));

-- ------------------------------------------------------------
-- Task 1.2 — DDL: Alter and Evolve the Schema
-- ------------------------------------------------------------

/* 1. Add an optional gstn_number column to customers
      to store business GST registration numbers. */

ALTER table customers
add gstn_number VARCHAR(20);

/* 2. Rename loyalty_tier to membership_tier in customers. */

ALTER table customers
rename column loyalty_tier to membership_tier;

/* 3. Increase the phone column length from VARCHAR(15) to VARCHAR(20). */

ALTER table customers
modify column phone VARCHAR(20); 

/* 4a. Before adding NOT NULL on supplier, replace any NULL values with 'Unknown Supplier' to avoid constraint violations. */

SET SQL_SAFE_UPDATES = 0;
UPDATE  products
set Supplier='Unknown Supplier'
where Supplier IS NULL;

/* 4b. Now safe to enforce NOT NULL on the supplier column. */

ALTER table products
modify Supplier varchar(100) NOT NULL;
SET SQL_SAFE_UPDATES = 1;

/* 5. Drop the coupon_code column from orders — no longer needed after business process change. */

ALTER table orders
DROP  Coupon_code ;

-- ------------------------------------------------------------
-- Task 1.3 — DML: Data Corrections
-- ------------------------------------------------------------
/* 1. Customer Nikhil Bose (ID 11) has provided his email address. */

update Customers
set email='nikhil@mail.com'
where customer_id=11;

/* 2. Order 1009 has been processed — move status to 'Shipped'. */

UPDATE orders
set status='Shipped'
Where order_id=1009;

/* 3. Product 108 received 300 additional units in a new stock delivery. */

update products
set stock_qty=stock_qty+300
where product_id=108;

/* 4. Data entry correction: item_id 2 was recorded as qty 3, but the actual dispatched quantity was 5. */

update order_items
set quantity=5
where item_id=2;

/* 5. Policy change: delete all returns filed with reason 'Changed mind'. */

SET SQL_SAFE_UPDATES = 0;
delete from returns
where reason='Changed mind';
SET SQL_SAFE_UPDATES = 1;

-- ============================================================
-- PHASE 2 — THE QUERY ENGINE
-- Topics: Aggregate Functions | Ordering | HAVING Clause |
--         String Functions | Date-Time Functions | Regular Expressions
-- ============================================================
 
-- ------------------------------------------------------------
-- Task 2.1 — Aggregate Functions and Ordering
-- ------------------------------------------------------------

/* 1. Total revenue per category (excluding cancelled orders).Revenue per line item = quantity * unit_price * (1 - discount_pct/100).
      Results ordered from highest to lowest revenue. */

select c.category_name,Round(SUM(o.quantity * o.unit_price * (1 - o.discount_pct / 100)),2) as total_revenue_per_category
from categories c join products p on c.category_id=p.category_id
join order_items o on o.product_id=p.product_id
group by c.category_name;

/* 2. Average order value (total revenue / distinct orders) per channel.Only Delivered orders are considered. */

SELECT 
    o.channel,
    ROUND(
        SUM(ot.quantity * ot.unit_price * (1 - ot.discount_pct / 100)) 
        / COUNT(DISTINCT o.order_id),
    2) AS avg_order_value
FROM orders o
JOIN order_items ot 
    ON o.order_id = ot.order_id
WHERE o.status = 'Delivered'
GROUP BY o.channel;

/* 3. Customers with more than 2 delivered orders — shows full_name, city, and order count, sorted descending. */

select c.full_name,c.city,count(o.order_id) as order_count
from customers c join orders o 
on c.customer_id=o.customer_id
where o.status='Delivered'
group by c.customer_id,c.full_name,c.city
having count(o.order_id)>2
order by count(o.order_id) DESC;

/* 4. Top 3 products by total units sold across all non-cancelled orders. */

select p.product_name,ROUND(SUM(ot.quantity ),2) as total_quantity_sold
from products p join order_items ot on p.product_id=ot.product_id
join orders o on o.order_id=ot.order_id 
where o.status != 'Cancelled'
group by product_name
order by total_quantity_sold desc
LImit 3;

/* 5. Count of distinct customers who used a coupon code. Also shows total orders with vs. without a coupon —
      using conditional aggregation (CASE WHEN inside SUM). */

ALTER TABLE orders
ADD COLUMN coupon_code VARCHAR(20);
UPDATE orders SET coupon_code = 'SAVE10' WHERE order_id IN (1001, 1006, 1012);
UPDATE orders SET coupon_code = 'FLAT200' WHERE order_id IN (1003, 1008, 1018);

select  COUNT(DISTINCT CASE WHEN coupon_code IS NOT NULL THEN customer_id END) AS customers_with_coupon,
SUM(case when coupon_code IS NOT NULL then 1 else 0 end) as orders_with_cuponcode,
SUM(case when coupon_code IS NOT NULL then 1 else 0 end) as order_without_cuponcode
from orders;

-- ------------------------------------------------------------
-- Task 2.2 — The HAVING Clause
-- ------------------------------------------------------------
 
/* 1. Product categories where the average listed unit price exceeds ₹10,000. */

select c.category_name,Round(avg(p.unit_price),2) as avg_unit_price
from products p join categories c on p.category_id=c.category_id
group by c.category_id,c.category_name
having avg(p.unit_price)>10000;

/* 2. Suppliers who supply more than one product in the catalog. */

select supplier,count(product_id) as product_count
from products
group by supplier
having count(product_id)>1;

/* 3. Months in 2023 where total Delivered orders exceeded 2. Month displayed in YYYY-MM format using DATE_FORMAT. */
      
select date_format(order_date,'%Y-%m') as Month,Count(*) as total_orders
from orders
where status='Delivered' and Year(order_date)=2023
group by date_format(order_date,'%Y-%m')
having count(*)>2;

/* 4. Customers whose total refund amount (across all returns) exceeds ₹50,000. Joins customers → orders → returns to associate refunds with customers. */
      
select c.customer_id,sum(r.refund_amount) as total_refund
from customers c join orders o on c.customer_id=o.customer_id 
join returns r on o.order_id=r.order_id
group by customer_id
having sum(r.refund_amount)>50000;

-- ------------------------------------------------------------
-- Task 2.3 — String Functions
-- ------------------------------------------------------------
 
/* 1. Extract each customer's first name and last name into separate columns from the full_name field using SUBSTRING_INDEX and SUBSTRING. */
      
select full_name, SUBSTRING_INDEX(full_name,' ' , 1) as first_name,
substring(full_name,locate(' ',full_name)+1) as last_name
from customers;

/* 2. Marketing display label formatted as:
      ARYAN M. | Gold | Mumbai
      (UPPER first name + initial of last name + membership_tier + city) */
      
select concat(upper(Substring_index(full_name,' ',1)),' ',upper(substring(full_name,locate(' ',full_name)+1,1)),' | ',
Membership_tier,' | ',city) as display_label
from customers;

/* 3. Extract the email domain (part after @) for all customers who have an email address on record. */
      
select customer_id,substring_index(email,'@',-1) as domain_names
from customers;

/* 4. Products whose name exceeds 20 characters. Shows product name and its character length, ordered by length descending. */

select product_name,char_length(product_name) as length
from products
where char_length(product_name)>20
order by char_length(product_name);

/* 5. Display all city values in proper Title Case —first letter uppercased, remainder lowercased.(SELECT only — not an UPDATE) */
      
select concat((left(full_name,1)),Lower(Right(full_name,length(full_name)-1))) as Fullname
from customers;

-- ------------------------------------------------------------
-- Task 2.4 — Date and Time Functions
-- ------------------------------------------------------------
 
/* 1. Number of days each customer has been registered as of today. */

select full_name,datediff(curdate(),registered_on) as num_of_days_since_registered
from customers;

/* 2. For each Delivered order: order_id, order_date, and the full month name (e.g., January, February). */

select order_id,order_date,monthname(order_date)
from orders
where status='Delivered';

/* 3. All orders placed in Q1 of 2023 (January through March). */

select order_id,order_date from orders
where order_date between '2023-01-01' and '2023-03-31';

/* 4. For each return: gap in days between order date and return date.
      Labels returns filed more than 15 days after the order as 'Late Return';
      others as 'Within Window'. */
      
select r.order_id,r.product_id,o.order_date,r.return_date,case when (datediff(r.return_date,o.order_date))>=15 then 'Late return'
		else 'Within Window'
        end as Flag
from orders o join returns r
on o.order_id=r.order_id;

/* 5. Most recent and earliest order dates, plus the difference in days —
      all in a single query. */
      
select max(order_date) as most_recent_order_date,
min(order_date) as earliest_order_date,
datediff(max(order_date),min(order_date)) as diff_between_days
from orders;

-- ------------------------------------------------------------
-- Task 2.5 — Regular Expressions
-- ------------------------------------------------------------

/* 1. Customers whose email does not follow the basic pattern
      something@something.something (flags potentially invalid emails). */
      
SELECT customer_id,email
FROM customers
WHERE email NOT REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$';

/* 2. Products whose product_name does not start with an uppercase English letter A–Z. */

SELECT product_name
FROM products
WHERE LEFT(product_name,1) NOT REGEXP '[A-Z]';

/* 3. Customers whose phone number does not match a valid 10-digit Indian mobile number (must start with 6, 7, 8, or 9). */

select customer_id
from customers
where phone NOT regexp '^[6-9][0-9]{9}$';

/* 4. Remove numeric digits from product names using REGEXP_REPLACE. Shows original name alongside the cleaned version. */

SELECT product_name AS original_name,REGEXP_REPLACE(product_name,'[0-9]','') AS cleaned_name
FROM products;

SELECT product_name,added_on,REGEXP_SUBSTR(CAST(added_on AS CHAR),'20[0-9]{2}') AS extracted_year
FROM products;

-- ============================================================
-- PHASE 3 — JOINS, SET THEORY, VIEWS, AND CTEs
-- Topics: Nested Queries | CTEs | Views | Set Theory |
--         Types of Joins | Outer Joins | Set Operations
-- ============================================================
 
-- ------------------------------------------------------------
-- Task 3.1 — Nested Queries and CTEs
-- ------------------------------------------------------------
/* 1. Products that have NEVER appeared in any order_items record (using a subquery in the WHERE clause). */

select product_name,category_id
from products p
where NOT exists (select 1
				  from order_items o
                  where p.product_id=o.product_id);
                  
/* 2. Customers whose total spend on delivered orders is ABOVE the average total spend across all customers (using a CTE). */

with total_amount_spent as (select c.customer_id,c.full_name,c.city,
ROUND(SUM(ot.quantity*ot.unit_price*(1-ot.discount_pct/100)),2) as total_spend
from customers c join orders o on c.customer_id=o.customer_id
join order_items ot on o.order_id=ot.order_id
where o.status='Delivered'
group by c.customer_id,c.full_name,c.city)
select full_name,city,total_spend
from total_amount_spent
where total_spend>(select avg(total_spend) from total_amount_spent );

/* 3. Recursive CTE: full category hierarchy.Top-level categories (parent_id IS NULL) show 'Top Level'
      as their parent name. */
      
WITH RECURSIVE category_hierarchy AS (
     -- Top-level categories
    SELECT category_id,category_name,parent_id,CAST('Top Level' AS CHAR(80)) AS parent_category
    FROM categories
    WHERE parent_id IS NULL
    UNION ALL
    -- Child categories
    SELECT c.category_id,c.category_name,c.parent_id,p.category_name AS parent_category
    FROM categories c
    JOIN category_hierarchy ch ON c.parent_id = ch.category_id
    JOIN categories p ON c.parent_id = p.category_id
)
SELECT category_id,category_name,parent_category
FROM category_hierarchy;

/* 4. Each customer's most recent order date using a correlated subquery.The subquery references the outer query's customer_id. */

select c.full_name,c.city
from customers c
where (c.customer_id) IN (select o.customer_id
						  from orders o
                          where o.order_date=
                          (select MAX(o.order_date) from orders o2
						  where o.customer_id=o2.customer_id)
                          );
/* 5. Slow-moving products: total units sold is strictly below the average units sold per product (CTE approach). */

with total_units as(select p.product_id,p.product_name,SUM(ot.quantity) as total_units_sold
from products p 
join order_items ot
on p.product_id=ot.product_id
join orders o
on o.order_id=ot.order_id
where o.status<>'Cancelled'
group by p.product_id,p.product_name)
select product_name,total_units_sold
from total_units
where total_units_sold<(select avg(total_units_sold) from total_units);

-- ------------------------------------------------------------
-- Task 3.2 — Types of Joins
-- ------------------------------------------------------------
 
/* 1. INNER JOIN: All order_items with product name, category name, and the placing customer's full name. */

select  o.order_id,p.product_name, ct.category_name,c.full_name,o.quantity
from categories ct 
join products p on ct.category_id=p.category_id
join order_items o on p.product_id=o.product_id
join orders od on o.order_id=od.order_id
join customers c on od.customer_id=c.customer_id;

/* 2. LEFT JOIN: Every customer and their total order count. Customers with zero orders still appear (count shown as 0). */
      
select c.customer_id,c.full_name,IFNULL(count(o.order_id),0) as total_orders
from customers c 
left join orders o
on c.customer_id=o.customer_id
group by c.customer_id,c.full_name;

/* 3. LEFT JOIN with NULL filter (simulating NOT IN): Products that have NEVER been ordered. */
select p.product_id,p.product_name,o.order_id
from products p 
left join order_items o
on p.product_id=o.product_id
where o.order_id is null;

/* 4. Self-Join: Pairs of products in the same category with a
      price difference > ₹50,000. Each pair shown only once
      (p1.product_id < p2.product_id). */
      
select p.product_name as product_1,p.unit_price as price_1,p1.product_name as product_2,p1.unit_price as price_2,c.category_name
from products p
join products p1
on p.category_id=p1.category_id and p.product_id < p1.product_id
join categories c on p.category_id=c.category_id
where p.unit_price-p1.unit_price>50000;

/* 5. Multi-table Join (4 tables): Every return with customer name, product name, return details, and original purchase channel. */
select c.full_name,p.product_name,r.return_date,r.reason,r.refund_amount,o.channel
from customers c join orders o on c.customer_id=o.customer_id
join returns r on o.order_id=r.order_id
join products p on r.product_id=p.product_id;

/* 6. Outer Join Analysis: Label each customer as 'Has Orders' or'No Orders' using CASE WHEN on a LEFT JOIN result. */
select distinct c.customer_id,c.full_name,case when o.order_id is null then 'No Orders'
												 else 'Has Orders' end as order_flag
from customers c 
left join orders o
on c.customer_id=o.customer_id;

-- ------------------------------------------------------------
-- Task 3.3 — Views
-- ------------------------------------------------------------
 
/* 1. View: vw_customer_order_summary Aggregated per-customer order stats and revenue. */
create view vw_customer_order_summary as(
select c.customer_id,c.full_name,c.city,c.membership_tier,count(o.order_id) as total_orders,
Sum(case when o.status='Delivered' then 1 else 0 end) as delivered_orders,
SUM(case when o.status='Cancelled' then 1 else 0 end) as cancelled_orders,
ROUND(SUM(ot.quantity * ot.unit_price * (1 - ot.discount_pct/100)),2) as total_revenue
from  customers c join orders o on c.customer_id=o.customer_id
join order_items ot on o.order_id=ot.order_id
group by c.customer_id,c.full_name);
select * from vw_customer_order_summary;

/* 2. View: vw_product_performance Per-product sales, revenue, and return count. */

create view vw_product_performance as (
select p.product_id,p.product_name,c.category_name,
ROUND(SUM(ot.quantity)) as total_units_sold,
ROUND(SUM(ot.quantity * ot.unit_price * (1 - ot.discount_pct/100)),2) as total_revenue,
count(distinct return_id) as return_count
from products p join categories c 
on c.category_id=p.category_id
join order_items ot on p.product_id=ot.product_id
join orders o on ot.order_id=o.order_id
left join returns r on o.order_id=r.order_id
where o.status='Delivered'
group by p.product_id,p.product_name,c.category_name);
select * from vw_product_performance;

/* 3. View: vw_monthly_sales Monthly aggregation of orders and revenue (YYYY-MM format). */

create view vw_monthly_sales as (select date_format(o.order_date,'%Y-%m') as month_label,count(o.order_id) as total_orders,
SUM(case when o.status='Delivered' then 1 else 0 end) as delivered_orders,
ROUND(SUM(ot.quantity * ot.unit_price * (1 - ot.discount_pct/100)),2) as total_revenue
from orders o join order_items ot
on o.order_id=ot.order_id
group by date_format(o.order_date,'%Y-%m')
); 

/* 4. Using vw_customer_order_summary: identify the single highest-revenue customer per state. */

select c.state,c.full_name,max(v.total_revenue) as highest_revenue
from customers c join vw_customer_order_summary v
on c.customer_id=v.customer_id
group by c.state,c.full_name;
/* 5. Can we UPDATE or DELETE through vw_customer_order_summary? Explanation and demonstration below. */
/*
In MySQL, UPDATE or DELETE operations are usually NOT allowed through 
vw_customer_order_summary because it is a non-updatable view.

Reason:
1. The view is created using aggregate functions such as SUM(), COUNT(), AVG(), etc.
2. It may contain GROUP BY clauses.
3. It is typically based on multiple joined tables.

MySQL allows UPDATE/DELETE only on simple updatable views that map directly
to rows of a single base table without aggregation or grouping.

Therefore, MySQL returns an error when attempting to modify data through
this view.
*/
-- Attempt to UPDATE the view
UPDATE vw_customer_order_summary
SET total_orders = 10
WHERE customer_id = 1;
-- MySQL Output:
-- ERROR 1288 (HY000):
-- The target table vw_customer_order_summary of the UPDATE is not updatable

-- Attempt to DELETE from the view
DELETE FROM vw_customer_order_summary
WHERE customer_id = 1;

-- MySQL Output:
-- ERROR 1288 (HY000):
-- The target table vw_customer_order_summary of the DELETE is not updatable

-- ------------------------------------------------------------
-- Task 3.4 — Set Operations
-- ------------------------------------------------------------
 
/* Warehouse city list used as the second dataset in Tasks 2–4. */
 
/* 1. UNION: Distinct list of all cities from customers OR warehouse list. */
SELECT city
FROM customers
UNION
SELECT 'Mumbai'
UNION
SELECT 'Delhi'
UNION
SELECT 'Bangalore'
UNION
SELECT 'Hyderabad'
UNION
SELECT 'Surat';

/* 2. INTERSECT simulation (LEFT JOIN): Cities that appear in BOTH
      the customers table and the warehouse list. */
      
SELECT DISTINCT c.city
FROM customers c
INNER JOIN
(
    SELECT 'Mumbai' AS city
    UNION ALL
    SELECT 'Delhi'
    UNION ALL
    SELECT 'Bangalore'
    UNION ALL
    SELECT 'Hyderabad'
    UNION ALL
    SELECT 'Surat'
) w
ON c.city = w.city;

/* 3. EXCEPT simulation (LEFT JOIN + NULL filter): Warehouse cities that have NO registered customers. */
      
SELECT w.city
FROM
(
    SELECT 'Mumbai' AS city
    UNION ALL
    SELECT 'Delhi'
    UNION ALL
    SELECT 'Bangalore'
    UNION ALL
    SELECT 'Hyderabad'
    UNION ALL
    SELECT 'Surat'
) w
LEFT JOIN customers c
ON w.city = c.city
WHERE c.city IS NULL;
/* 4a. UNION — returns DISTINCT product names (duplicates removed). */
-- UNION deduplplicates rows. Use when you want unique results.-
SELECT p.product_name
FROM products p
JOIN order_items oi
ON p.product_id = oi.product_id
UNION
SELECT product_name
FROM products;
/* 4b. UNION ALL — includes ALL rows including duplicates.
       Use when you need every occurrence for counting/auditing. */
SELECT p.product_name
FROM products p
JOIN order_items oi
ON p.product_id = oi.product_id
UNION ALL
SELECT product_name
FROM products;

-- ============================================================
-- PHASE 4 — WINDOW FUNCTIONS MASTERCLASS
-- Topics: Rank Functions | Partitioning | Named Windows |
--         Frames | Lead and Lag Functions
-- ============================================================
 
-- ------------------------------------------------------------
-- Task 4.1 — Rank Functions
-- ------------------------------------------------------------
 
/*
   Scenario where RANK, DENSE_RANK, and ROW_NUMBER differ:
   If two customers share the highest spend (tied at rank 1),
   RANK()       → both get 1, next customer gets 3 (gap)
   DENSE_RANK() → both get 1, next customer gets 2 (no gap)
   ROW_NUMBER() → assigns 1 and 2 arbitrarily (no ties)
*/
 
/* 2. Top 2 products by total revenue within each category using DENSE_RANK (ties handled correctly). */

with top_rank as (select p.category_id,p.product_id,p.product_name,
ROUND(SUM(ot.quantity * ot.unit_price * (1 - ot.discount_pct/100)),2) as total_revenue,
dense_rank() over (partition by p.category_id order by ROUND(SUM(ot.quantity * ot.unit_price * (1 - ot.discount_pct/100)),2) desc) as ranking
from products p join order_items ot
on p.product_id=ot.product_id
group by p.product_id,p.category_id,p.product_name)
select  category_id,product_id,product_name,total_revenue,ranking
from top_rank
where ranking<=2
ORDER BY category_id, ranking;

/* 1. Rank all customers by total revenue from delivered orders using RANK, DENSE_RANK, and ROW_NUMBER side by side. */

select c.customer_id,ROUND(SUM(ot.quantity * ot.unit_price * (1 - ot.discount_pct/100)),2) as total_revenue,
rank() over ( order by ROUND(SUM(ot.quantity * ot.unit_price * (1 - ot.discount_pct/100)),2) desc) as ranking,
dense_rank() over ( order by ROUND(SUM(ot.quantity * ot.unit_price * (1 - ot.discount_pct/100)),2) desc) as densed_ranking,
row_number() over ( order by ROUND(SUM(ot.quantity * ot.unit_price * (1 - ot.discount_pct/100)),2) desc) as row_number_ranking
from customers c join orders o
on c.customer_id=o.customer_id
join order_items ot on o.order_id=ot.order_id
group by c.customer_id;

/* 3. Sequential purchase number per customer using ROW_NUMBER, ordered by order_date ascending. */

select distinct c.customer_id,o.order_date,
row_number() over (partition by c.customer_id order by order_date desc) as row_ranking
from customers c join orders o
on c.customer_id=o.customer_id;

/* 4. Divide customers into 4 quartile groups by total delivered spend using NTILE(4). Q1 = lowest spend, Q4 = highest. */

with customer_spend as(select c.customer_id,ROUND(SUM(ot.quantity * ot.unit_price * (1 - ot.discount_pct/100)),2) as total_delivery_spend
from customers c join orders o
on c.customer_id=o.customer_id
join order_items ot on o.order_id=ot.order_id
where o.status='delivered'
group by c.customer_id)
select customer_id,total_delivery_spend,
CASE NTILE(4) OVER (ORDER BY total_delivery_spend)
WHEN 1 THEN 'Q1'
WHEN 2 THEN 'Q2'
WHEN 3 THEN 'Q3'
WHEN 4 THEN 'Q4'
END AS quartile
FROM customer_spend;
-- ------------------------------------------------------------
-- Task 4.2 — Partitioning and Named Windows
-- ------------------------------------------------------------
 
/* 1. Revenue contribution of each order_items line as a percentage of its category's total revenue. */

with product_revenue as
 (select c.category_id,c.category_name,p.product_name, SUM(ot.unit_price*ot.quantity) as item_revenue
from categories c join products p
on c.category_id=p.category_id
join order_items ot on p.product_id=ot.product_id
group by c.category_id,c.category_name,p.product_id,p.product_name)

select category_name,product_name,item_revenue,
ROUND(SUM(item_revenue) over (partition by category_id),2) as category_revenue,
ROUND(item_revenue*10/SUM(item_revenue) over (partition by category_id),2) as contribution_pct
from product_revenue;

/* 2. Running cumulative total and running average revenue per customer's delivered orders, ordered by order_date. */

with revenue_by_customer as(select c.customer_id,c.full_name,o.order_date,
ROUND(SUM(ot.unit_price*ot.quantity*(1-ot.discount_pct/100)),2) as total_revenue
from customers c join orders o on c.customer_id=o.customer_id
join order_items ot on o.order_id=ot.order_id
where o.status='Delivered'
group by c.customer_id,full_name,o.order_id)
select full_name,order_date,total_revenue,
SUM(total_revenue) over (partition by customer_id order by order_date   rows between unbounded preceding and current row) 
as running_total,
AVG(total_revenue) over (partition by customer_id order by order_date  rows between unbounded preceding and current row) 
as avg_running_total
from revenue_by_customer;

/* 3. Named window w_customer reused across ROW_NUMBER, SUM, and AVG in a single query (using the WINDOW clause). */

with revenue_by_customer as(select c.customer_id,c.full_name,o.order_date,
ROUND(SUM(ot.unit_price*ot.quantity*(1-ot.discount_pct/100)),2) as line_revenue
from customers c join orders o on c.customer_id=o.customer_id
join order_items ot on o.order_id=ot.order_id
where o.status='Delivered'
group by c.customer_id,full_name,o.order_id)
select full_name,order_date,line_revenue,
row_number() over w_customer as row_ranking,
ROUND(SUM(line_revenue) over w_customer,2) as running_total,
ROUND(AVG(line_revenue) over w_customer,2) as avg_running_total
from revenue_by_customer
window w_customer as (partition by customer_id order by order_date   rows between unbounded preceding and current row)  ;

/* 4. MIN and MAX unit_price from order_items per product compared
      against the current listed price — labelled 'Price Deviated' or 'Consistent'. */
      
with product_price as (select p.product_id,product_name,p.unit_price as listed_price,
 MAX(o.unit_price) over (partition by product_id) as max_order_price,
 Min(o.unit_price) over (partition by product_id) as min_order_price
from products p join order_items o 
on p.product_id=o.product_id)
select Distinct product_name,listed_price,min_order_price,max_order_price,
case when listed_price!=max_order_price or listed_price!=min_order_price  then 'Price Deviated'
else 'Consistent' end as price_flag
from product_price;

-- ------------------------------------------------------------
-- Task 4.3 — Frames
-- ------------------------------------------------------------
 
/* 1. 3-order moving average revenue per customer using a ROWS frame. */

with revenue_by_customer as(select c.customer_id,c.full_name,o.order_date,
ROUND(SUM(ot.unit_price*ot.quantity*(1-ot.discount_pct/100)),2) as total_revenue
from customers c join orders o on c.customer_id=o.customer_id
join order_items ot on o.order_id=ot.order_id
where o.status='Delivered'
group by c.customer_id,full_name,o.order_date)
select full_name,order_date,total_revenue,
AVG(total_revenue) over (partition by customer_id order by order_date  rows between 2 preceding and current row) 
as avg_running_total
from revenue_by_customer;

/* 2. Company-wide cumulative revenue timeline across all delivered orders using a RANGE frame with UNBOUNDED PRECEDING. */

with revenue_by_customer as(select c.customer_id,c.full_name,o.order_date,
ROUND(SUM(ot.unit_price*ot.quantity*(1-ot.discount_pct/100)),2) as total_revenue
from customers c join orders o on c.customer_id=o.customer_id
join order_items ot on o.order_id=ot.order_id
where o.status='Delivered'
group by c.customer_id,full_name,o.order_date)
select full_name,order_date,total_revenue,
SUM(total_revenue) over ( order by order_date  range between unbounded preceding and current row) 
as running_cumulative_total
from revenue_by_customer;

/* 3. 7-day rolling count of orders for each order date using a RANGE frame with an INTERVAL of 6 days preceding. */

select order_date,  
COUNT(*) OVER (ORDER BY order_date RANGE BETWEEN INTERVAL 6 DAY
PRECEDING AND CURRENT ROW) as num_of_orders
from orders;

/* 4. FIRST_VALUE and LAST_VALUE per customer across order_items, showing revenue of customer's first and last order line. */

with revenue_by_customer as(select c.customer_id,c.full_name,o.order_date,
ROUND(SUM(ot.unit_price*ot.quantity*(1-ot.discount_pct/100)),2) as line_revenue
from customers c join orders o on c.customer_id=o.customer_id
join order_items ot on o.order_id=ot.order_id
where o.status='Delivered'
group by c.customer_id,full_name,o.order_id,o.order_date)
select full_name,order_date,line_revenue,
FIRST_VALUE(line_revenue) over (partition by customer_id order by order_date rows between unbounded preceding and unbounded following)
as first_revenue,
LAST_VALUE(line_revenue) over (partition by customer_id order by order_date rows between unbounded preceding and unbounded following)
as last_revenue
from revenue_by_customer;
-- ------------------------------------------------------------
-- Task 4.4 — Lead and Lag Functions
-- ------------------------------------------------------------
 
/* 1. Gap in days between consecutive orders per customer using LAG. Also identifies the customer with the largest single gap. */

with cal_order_date as(select  c.customer_id,c.full_name,o.order_date,
LAG(o.order_date,1) over (partition by c.customer_id order by o.order_date) as previous_order_date
from customers c join orders o
on c.customer_id=o.customer_id)
select full_name,order_date,previous_order_date,datediff(order_date,previous_order_date) as gap_between_days
from cal_order_date;

/* 2. For each order: next order date and next order revenue using LEAD. */

with order_revenue as (select c.customer_id,c.full_name,o.order_date,
ROUND(SUM(ot.unit_price*ot.quantity*(1-ot.discount_pct/100)),2) as total_revenue
from customers c join orders o on c.customer_id=o.customer_id
join order_items ot on o.order_id=ot.order_id
where o.status='Delivered'
group by c.customer_id,full_name,o.order_id,o.order_date)
select full_name,order_date,total_revenue,
LEAD(order_date,1) over (partition by customer_id order by order_date) as next_order_date,
LEAD(total_revenue,1) over (partition by customer_id order by order_date) as next_total_revenue
from order_revenue;

/* 3. Month-over-month revenue comparison using LAG on vw_monthly_sales. */

select * from vw_monthly_sales;
select month_label,total_revenue,
COALESCE(LAG(total_revenue,1) over (order by month_label),0) as prev_month_revenue,
ABS((total_revenue)-coalesce(LAG(total_revenue,1) over (order by month_label),0)) as absolute_revenue_change,
case when  LAG(total_revenue,1)OVER (ORDER BY month_label) IS NULL THEN NULL
ELSE ROUND(
	(total_revenue-LAG(total_revenue,1) over (order by month_label))*100/LAG(total_revenue,1) over (order by month_label)
,2) end as percentage_change
from vw_monthly_sales;

/* 4. Detect repeat purchases of the same product by the same customer using LAG partitioned by (customer_id, product_id). */

with repeat_purchase as (select c.full_name,p.product_name,p.product_id,o.order_date,
 LAG(o.order_date,1) OVER (PARTITION BY c.customer_id, p.product_id ORDER BY o.order_date) AS first_purchase_date
 FROM customers c JOIN orders o
ON c.customer_id = o.customer_id 
JOIN order_items ot ON o.order_id = ot.order_id
JOIN products p ON ot.product_id = p.product_id)
SELECT full_name,product_name,first_purchase_date,order_date AS repeat_purchase_date
FROM repeat_purchase
WHERE first_purchase_date IS NOT NULL;

-- ============================================================
-- PHASE 5 — GRAND FINALE: THE RETAILPULSE DASHBOARD REPORT
-- Topics: Full integration of all phases
-- Each query is a single executable statement with CTEs.
-- ============================================================
 
-- ------------------------------------------------------------
-- Q1 — Customer Lifetime Value Tier Report
-- ------------------------------------------------------------
/*
   For every customer, reports:
   full_name, city, loyalty_tier, total_orders, delivered_orders,
   total_spend (from Delivered orders), tier_rank (DENSE_RANK within
   tier by spend descending), overall_percentile (PERCENT_RANK across
   all customers by total spend).
   Ordered by loyalty_tier, then tier_rank.
*/

with customer_report as(
select c.customer_id,c.full_name,c.city,c.membership_tier,
count(o.order_id) as total_orders,
SUM(case when o.status='Delivered' then 1 else 0 end) as delivered_count,
ROUND(SUM(ot.unit_price*ot.quantity*(1-discount_pct/100)),2) as total_spend
from customers c join orders o on c.customer_id=o.customer_id
join order_items ot on o.order_id=ot.order_id
group by c.customer_id,c.full_name,c.city)
select full_name,city,membership_tier,total_orders,delivered_count,total_spend,
dense_rank() over (partition by membership_tier order by total_spend desc) as tier_rank,
ROUND(percent_rank() over (order by total_spend desc),2) as overall_percentile
from customer_report
order by membership_tier,tier_rank;

-- ------------------------------------------------------------
-- Q2 — Product Health Dashboard
-- ------------------------------------------------------------
/*
   For every product, reports:
   product_name, category_name, stock_qty, unit_price,
   total_units_sold, total_revenue, return_count, return_rate,
   health_label (High Performer / Returned Frequently /
                 Low Traction / Normal).
   Ordered by total_revenue descending.
*/

with product_report as (select p.product_name,c.category_name,p.unit_price as listed_price,
coalesce(SUM(ot.quantity),0) as total_units_sold,
coalesce(ROUND(SUM(ot.unit_price*ot.quantity*(1-discount_pct/100)),2),0) as total_revenue,
count(r.return_id) as return_count,
(count(return_id)/coalesce(SUM(ot.quantity),0))*100 as return_rate
from categories c join products p
on c.category_id=p.category_id
join order_items ot on p.product_id=ot.product_id
join orders o on ot.order_id=o.order_id
left join returns r on o.order_id=r.return_id
where o.status<>'Cancelled'
group by c.category_id,c.category_name,p.product_id)
select product_name,category_name,total_units_sold,total_revenue,return_count,
case when total_revenue>10000 and return_rate<5 then 'High Performer'
when return_rate>10 then 'Returned Frequently'
when total_units_sold<5 then 'Low Traction'
else 'Normal' end as health_label
from product_report
order by total_revenue;

-- ------------------------------------------------------------
-- Q3 — Channel and Coupon Effectiveness
-- ------------------------------------------------------------
/*
   Using only Delivered orders — no subqueries.
   Per channel: total revenue, avg order value, unique customers.
   For Online specifically: coupon vs non-coupon order percentages
   and average revenue for each.
   All percentages rounded to 2 decimal places.*/
   
select o.channel,ROUND(SUM(ot.unit_price*ot.quantity*(1-ot.discount_pct/100)),2) as total_revenue,
ROUND(SUM(ot.unit_price*ot.quantity*(1-ot.discount_pct/100))/count(distinct o.order_id),2) as avg_order_revenue,
COUNT(DISTINCT o.customer_id) AS unique_customers,
ROUND(
	COUNT(CASE WHEN o.channel = 'Online'AND o.coupon_code IS NOT NULL THEN 1 END) * 100.0
	/
	NULLIF(COUNT(CASE WHEN o.channel = 'Online' THEN 1 END),0)
    ,2) AS online_coupon_order_pct,
 ROUND(
	COUNT(CASE WHEN o.channel = 'Online'AND o.coupon_code IS NULL THEN 1 END) * 100.0
	/
	NULLIF(COUNT(CASE WHEN o.channel = 'Online' THEN 1 END),0)
    ,2) AS online_non_coupon_order_pct,
ROUND(AVG(CASE WHEN o.channel = 'Online'
				AND o.coupon_code IS NOT NULL
                THEN ot.quantity * ot.unit_price *(1 - ot.discount_pct/100) END),
    2) AS avg_coupon_order_revenue,
ROUND(AVG(CASE WHEN o.channel = 'Online'AND o.coupon_code IS NULL THEN ot.quantity * ot.unit_price *(1 - ot.discount_pct/100) END),
    2) AS avg_non_coupon_order_revenue
FROM orders o
JOIN order_items ot
    ON o.order_id = ot.order_id
WHERE o.status = 'Delivered'
GROUP BY o.channel;

-- ------------------------------------------------------------
-- Q4 — Customer Purchase Trajectory
-- ------------------------------------------------------------
/*
   For every customer with at least 2 delivered orders:
   full_name, purchase_number (ROW_NUMBER), order_date,
   order_revenue, revenue_change (LAG diff from previous order),
   moving_avg_2 (2-order moving average), cumulative_revenue.
   Ordered by full_name, then order_date.
*/

with order_revenue as (select c.customer_id,c.full_name,o.order_date,
ROUND(SUM(ot.unit_price*ot.quantity*(1-ot.discount_pct/100)),2) as total_revenue,count(o.order_id) as num_of_orders
from customers c join orders o on c.customer_id=o.customer_id
join order_items ot on o.order_id=ot.order_id
where o.status='Delivered'
group by c.customer_id,full_name,o.order_id,o.order_date
having count(o.order_id)>=2)
select full_name,order_date,total_revenue,
total_revenue-LAG(total_revenue,1) over (partition by customer_id order by order_date) as revenue_change,
AVG(total_revenue) over (order by order_date rows between 1 preceding and current row) as revenue_change,
SUM(total_revenue)  over (order by order_date) as cumlative_running
from order_revenue;

-- ------------------------------------------------------------
-- Q5 — Monthly Registration Cohort Analysis
-- ------------------------------------------------------------
/*
   Groups customers by the month they registered (cohort_month).
   Reports: cohort_month, cohort_size, total_cohort_revenue,
   best_revenue_month (month with highest revenue for that cohort),
   cohort_label (High Value Cohort / Standard Cohort).
   Ordered by cohort_month.
*/
with monthly_report as (select date_format(c.registered_on,'%Y-%m') as cohort_month,count(c.customer_id) as num_of_people_registered,
ROUND(SUM(ot.unit_price*ot.quantity*(1-ot.discount_pct/100)),2) as total_cohort_revenue,
rank() over (order by ROUND(SUM(ot.unit_price*ot.quantity*(1-ot.discount_pct/100)),2) desc) as best_revenue_month
from  customers c join orders o on c.customer_id=o.customer_id
join order_items ot on o.order_id=ot.order_id
where o.status='Delivered' 
group by date_format(c.registered_on,'%Y-%m'),c.customer_id)
select cohort_month,num_of_people_registered,total_cohort_revenue,best_revenue_month ,
case when total_cohort_revenue>200000 then 'High Value Cohort' else 'Standard Cohort' end as cohort_label
from monthly_report
order by cohort_month;


