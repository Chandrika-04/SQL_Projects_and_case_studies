USE Ecommerce_Bussiness;
-- Q1 — List All Customers from a Specific City
SELECT full_name,email,city,tier 
FROM customers
WHERE city= 'Hyderabad' OR city='Bangalore'
ORDER BY tier DESC , full_name ASC;

-- Q2 — Products Below a Price Threshold
SELECT product_name, category, unit_price, stock_qty
FROM Products
WHERE unit_price<10000
ORDER BY unit_price ASC;

-- Q3 — Count of Employees per Department
SELECT d.dept_name, COUNT( e.emp_id) AS employee_count
FROM Employees e
JOIN departments d
on e.dept_id=d.dept_id
group by d.dept_name
having count(e.emp_id)>=2
ORDER BY employee_count DESC;

-- Q4 — Total Revenue per Order
Select order_id, SUM(unit_price*quantity) As Total_Revenue
FROM order_items
GROUP BY order_id;

-- Q5 — Orders Placed in Q1 2024
SELECT order_id, customer_id, order_date, status
FROM Orders
WHERE order_date  BETWEEN '2024-01-01' AND '2024-03-01'
ORDER by order_date ASC;

-- Q6 — Top 5 Customers by Total Spend
 -- Identify the highest-spending customers based on completed payments for a loyalty reward 
 -- Expected Output columns:customer_id, full_name, tier, total_spent
-- Filter: Only  Completed payments
-- Limit: Top 5
select c.customer_id, c.full_name,c.tier,SUM(p.paid_amount) as total_spent
from customers c
join orders o
on c.customer_id=o.customer_id
join payments p
on o.order_id=p.order_id where p.status='completed'
group by o.order_id
order by total_spent desc
limit 5;

-- Q7 — Monthly Revenue Trend in 2024
-- Scenario: The CFO wants a month-by-month revenue summary for 2024 using payment data
select date_format(payment_date,'%Y %M') as month, sum(paid_amount) as total_revenue, count(order_id) as order_count
from payments
where year(payment_date)=2024 and status='completed'
group by date_format(payment_date,'%Y %M')
order by month asc;

-- Q8 — Products Never Ordered
 -- The warehouse manager wants to know which products have never appeared in any order
 
select p.product_id, p.product_name, p.category, p.stock_qty
from products p
where  NOT EXISTS (select 1  from order_items o where p.product_id=o.product_id);

-- Q9 — Employees and Their Managers (Self Join)
SELECT 
    e.emp_id,
    e.fullname AS employee,
    m.fullname AS manager
FROM employees e
LEFT JOIN employees m 
    ON e.manager_id = m.emp_id;
    
    
-- Q10 — Average Order Value per Customer Tier
SELECT 
    c.tier,
    AVG(order_value) AS avg_order_value,
    COUNT(order_id) AS total_orders
FROM (
    SELECT 
        od.order_id,
        od.customer_id,
        SUM(o.quantity * o.unit_price) AS order_value
    FROM orders od
    JOIN order_items o
        ON od.order_id = o.order_id
    GROUP BY od.order_id, od.customer_id
) t
JOIN customers c
    ON t.customer_id = c.customer_id
GROUP BY c.tier;

-- Q12 — String Manipulation — Masked Email Report
--  For a GDPR-compliance report, generate a masked version of each customer email
SELECT 
    customer_id,
    full_name,
    CONCAT('****@', SUBSTRING_INDEX(email, '@', -1)) AS masked_email
FROM customers;


-- Q13 — Days Since Last Order per Customer
--  CRM team wants to know how many days ago each customer last placed an order
with last_date as (select c.customer_id, c.full_name, o.order_date, 
rank() over (partition by c.customer_id order by o.order_date desc ) as rnk
from customers c
join orders o on
c.customer_id=o.customer_id)
select customer_id, full_name, datediff(curdate(),order_date) as days_since_last_order
from last_date
where rnk=1
order by days_since_last_order desc;
-- method 2
SELECT 
    c.customer_id,
    c.full_name,
    DATEDIFF(CURDATE(), MAX(o.order_date)) AS days_since_last_order
FROM customers c
JOIN orders o 
    ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY days_since_last_order DESC;

-- Q14 — Revenue by Category (with Discount Applied)
-- Compute actual revenue per product category after applying discounts
select p.category,round(SUM(o.quantity *o. unit_price * (1 -o. discount/100)),2) as total_revenue
from products P 
join order_items o
on p.product_id=o.product_id
group by p.category;


-- Q15 — Employees Hired After 2019 with Salary Above Department Average
-- Find employees hired after 2019 whose salary exceeds their department's average.
select e.fullname, e.hiredate, e.salary, d.dept_name, avg(e.salary) as dept_avg_salary
from employees e 
join departments d
on e.dept_id=d.dept_id
where year(hiredate)>2019 and 
salary > (select avg(salary) from employees e2 where e2.dept_id=e.dept_id group by e.dept_id)
group by e.emp_id;

-- Q16 — Rank Customers by Total Spend Within Each Tie
-- Marketing wants to rank customers within each tier based on total spending.
select full_name, tier, total_spending ,RANK() over (partition by tier ORDER BY total_spending DESC) as rank_in_tier 
from (select c.full_name, c.tier,SUM(paid_amount) as total_spending
from customers c 
join orders o
on  c.customer_id=o.customer_id 
join payments p on o.order_id=p.order_id
group by c.customer_id,c.full_name, c.tier)t
order by tier,rank_in_tier ;

--  17.Finance wants a running cumulative total of payment revenue ordered by payment date
select payment_id, payment_date,paid_amount,
sum(paid_amount) over (order by payment_date rows between unbounded preceding and current row) as running_total
from payments
order by payment_date ASC;

-- 18. Build a sales rep performance report using a named window
select fullname, total_orders,total_revenue, 
rank() over w as revenue_rank, 
dense_rank() over w as dense_revenue_rank
 from (select e.fullname,count(o.order_id)  as total_orders , 
SUM(o.quantity*o.unit_price*(1-o.discount/100)) as total_revenue
from employees e
join orders od on e.emp_id=od.emp_id
join order_items o on od.order_id=o.order_id
group by e.fullname) t 
window w as (order by total_revenue desc,total_orders desc);

-- 19  Using a CTE, calculate each month's revenue and the percentage growth vs the previous month.
with revenue as (select DATE_FORMAT(payment_date, '%Y-%m') AS month , 
				SUM(paid_amount) as revenue
				from payments
                group by DATE_FORMAT(payment_date, '%Y-%m') )
                
select month,revenue, 
	LAG(revenue) over (order by month) as prev_month_revenue,
    ROUND(
        (revenue - LAG(revenue) OVER (ORDER BY month)) * 100.0 
        / LAG(revenue) OVER (ORDER BY month),
    2) AS pct_growth
from revenue;

-- 20. Create a reusable view  vw_active_customer_summary for customers with at least one delivered
-- order. Then query it for Gold and Platinum customers with spend over ₹50,000

create view vw_active_summary as
 (select c.customer_id,
 SUM(o.quantity*o.unit_price*(1-o.discount/100)) as spend, 
 SUM(case when od.status='delivered' then 1 else 0 end) as delivery_count
from customers c
join orders od on c.customer_id=od.customer_id
join order_items o on od.order_id=o.order_id
where c.tier='Gold' or c.tier='Platinum'
group by c.customer_id
having SUM(o.quantity*o.unit_price*(1-o.discount/100)) >50000 and
SUM(case when od.status='delivered' then 1 else 0 end)>=1);

-- Q21 — Full Management Chain (Two-Level Self Join)
-- Show every employee with their direct manager and their manager's manager
SELECT 
    e.fullname AS employee,
    m.fullname AS manager,
    mm.fullname AS manager_manager
FROM employees e
LEFT JOIN employees m 
    ON e.manager_id = m.emp_id
LEFT JOIN employees mm 
    ON m.manager_id = mm.emp_id;
    
-- Q22 — REGEXP: Gmail Customers and Two-Word Names
-- Find customers using Gmail (OAuth integration). Also find customers with exactly two-word names
select email ,full_name from customers
WHERE email REGEXP '^[A-Za-z0-9._%+-]+@gmail\\.com$'
  AND full_name REGEXP '^[A-Za-z]+ [A-Za-z]+$';
  
-- Q23 — DENSE_RANK Top 3 Products per Category by Revenue
-- Identify the top 3 revenue-generating products within each category.

with revenue_cte as ( 
select p.category,p.product_name,SUM(o.unit_price*o.quantity*(1-o.discount/100)) as total_revenue
from products p join order_items o 
on p.product_id=o.product_id
group by p.category,p.product_name),
ranked_cte as (select *,
dense_rank() over (partition by category order by total_revenue desc) as rank_in_category from revenue_cte)
SELECT category, product_name, total_revenue,rank_in_category
FROM ranked_cte
WHERE rank_in_category <= 3
ORDER BY category, total_revenue DESC;

-- Q24 — Orders with No Payment or Failed Payment
select o.order_id, c.full_name, o.order_date, o.status,p.status as payment_status
from customers c join orders o on c.customer_id=o.customer_id
join payments p on o.order_id=p.order_id
where p.order_id IS NULL and  p.status='failed';

-- Q25 — Pivot-Style Report: Orders per Status per Month
-- Operations wants a matrix of order counts per status for each month of 2024.
select DATE_FORMAT(order_date, '%Y-%m') as month, 
sum(case when status='Pending' then 1 else 0 end) as pending,
sum(case when status='Processing' then 1 else 0 end) as processing,
sum(case when status='Shipped' then 1 else 0 end) as shipped,
sum(case when status='Delivered' then 1 else 0 end) as delivered,
sum(case when status='Cancelled' then 1 else 0 end) as cancelled
from orders
where year(order_date)=2024
group by DATE_FORMAT(order_date, '%Y-%m') ;

-- 26.Duplicate Detection: Customers with Same Name
-- Data quality team suspects duplicate registrations. Find names registered more than once.
SELECT 
    full_name,
    COUNT(*) AS occurrence_count
FROM customers
GROUP BY full_name
HAVING COUNT(*) > 1;

-- Q27 — Products Ordered by Both Customer 3 and Customer 8
--  Find products that appear in orders from both customers — simulating INTERSECT in MySQL.
select p.product_id, p.product_name
from  customers c join orders od on c.customer_id=od.customer_id
join order_items o on od.order_id=o.order_id
join products p on o.product_id=p.product_id
where c.customer_id IN(3,8)
group by p.product_id,p.product_name
HAVING COUNT(DISTINCT od.customer_id) = 2;

-- Q28 — Most Popular Payment Method per Customer Tier
 -- Find the most-used payment method within each customer tier.
with popular_method_usage as(
select c.tier,p.method,count(*) as usage_count
from customers c join orders o on c.customer_id=o.customer_id
join payments p on o.order_id=p.order_id
GROUP BY c.tier, p.method),
method_rank as(select *, rank() over (  PARTITION BY tier ORDER BY usage_count DESC) as rank_in_tier
from popular_method_usage)
SELECT tier, method, usage_count
FROM method_rank
WHERE rank_in_tier = 1;

-- Q29 — List All Orders with Customer Names
-- Scenario: The support team needs a simple report of all orders showing the customer's name, order date, and current status.
-- Expected Output columns: order_id, full_name, order_date, status
-- Ordered by: order_date DESC
select o.order_id,c.full_name,o.order_date,o.status
from customers c
join orders o
on c.customer_id=o.customer_id
order by o.order_date DESC;

-- Q30 — Products in the Electronics Category Sorted by Price
-- : A customer wants to browse all Electronics products from cheapest to most expensive.
-- Expected Output columns: product_name, unit_price, stock_qty, supplier
-- Ordered by: unit_price ASC
select product_name,category,unit_price,stock_qty,supplier
from products
where category='Electronics'
order by unit_price asc;

-- Q31 — Total Number of Orders per Status
-- Scenario: Operations manager wants a quick count of how many orders exist in each status.
-- Expected Output columns: status, order_count
-- Ordered by: order_count DESC
select status,count(*) as order_count
from orders
group by status
order by order_count desc;

-- Q32 — Employees with Salary Between 60,000 and 90,000
-- Scenario: HR wants to review mid-range salaries for an appraisal exercise.
-- Expected Output columns: full_name, email, salary, dept_name
-- Ordered by: salary DESC
select e.fullname,e.email,e.salary,d.dept_name
from employees e join departments d
on e.dept_id=d.dept_id
where e.salary between 60000 and 90000
order by salary desc;

-- Q33 — Most Recently Joined Customer per Tier
-- Scenario: The welcome team wants to identify the newest customer in each tier.
-- Expected Output columns: tier, full_name, email, joined_date

with latest_join_date as ( select tier,full_name,email,joined_date,
rank() over (partition by tier order by joined_date desc) as ranking
from customers)
select tier,full_name,email,joined_date
from latest_join_date
where ranking = 1;

-- Q34 — Payment Method Usage Summary
-- Scenario: Finance wants to know how many times each payment method was used and the total amount collected per method for completed payments.
-- Expected Output columns: method, usage_count, total_collected
-- Ordered by: total_collected DESC
select method,count(*) as usage_count,SUM(paid_amount) as total_collected
from payments
group by method
order by total_collected desc;

-- Q35 — Customers Who Have Never Placed an Order
-- Scenario: The sales team wants a list of registered customers who have not placed a single order yet, for a re-engagement campaign.
-- Expected Output columns: customer_id, full_name, email, tier, joined_date
select c.customer_id,c.full_name,c.email,c.tier,c.joined_date
from customers c
where NOT exists(select 1
                from orders o
                where c.customer_id=o.customer_id);
                
-- Q36 — Employee Tenure in Years and Months
-- Scenario: HR needs a report showing how long each employee has been with the company in a readable format.
--  Output columns: full_name, hire_date, years_of_service, months_of_service
select fullname,hiredate,timestampdiff(Year,hiredate,curdate()) as years_of_service,
timestampdiff(Month,hiredate,curdate()) as months_of_service
from employees;

-- Q37 — Orders Containing More Than One Product
-- Scenario: Analytics team wants to analyse multi-item orders to study basket size.
-- Expected Output columns: order_id, customer_name, item_count, order_total
-- Filter: Orders with more than 1 line item

select o.order_id,c.full_name,count(p.product_id) as item_count , ROUND(SUM(o.quantity * o.unit_price * (1 - o.discount/100)),2) AS order_total
from customers c join orders od on c.customer_id=od.customer_id
join order_items o on od.order_id=o.order_id
join products p on o.product_id=p.product_id
group by o.order_id,c.full_name
having count(p.product_id)>1;

-- Q38 — Category with Highest Average Product Price
-- Scenario: Procurement wants to know which product category has the highest average unit price.
-- Expected Output columns: category, avg_price, product_count
-- Ordered by: avg_price DESC
select category,ROUND(AVG(unit_price*stock_qty),2) as avg_price,count(*) as product_count
from products
group by category
order by AVG(unit_price*stock_qty) desc limit 1;

-- Q39 — Full Name Formatting and Email Domain Extraction
-- Scenario: The IT team needs a report with customer names in UPPER CASE and their email domains extracted separately.
-- Expected Output columns: customer_id, upper_name, email_domain
select customer_id,UPPER(full_name) as upper_name, SUBSTRING(email FROM POSITION('@' IN email) + 1) AS email_domain
FROM customers;

-- Q40 — Orders Delivered to a Different City Than Customer's Home City
-- Scenario: Logistics team wants to find orders where the shipping city differs from the customer's registered city (possible gift orders or relocation).
-- Expected Output columns: order_id, customer_name, customer_city, shipping_city
select o.order_id,c.full_name,c.city as customer_city , o.shipping_city
from customers c
join orders o
on c.customer_id=o.order_id
where c.city <> o.shipping_city;

-- Q41 — Top Selling Product per Category by Quantity
-- Scenario: Inventory team wants to know which product sold the highest total quantity in each category.
-- Expected Output columns: category, product_name, total_qty_sold
WITH product_sales AS (
    SELECT 
        p.category,
        p.product_name,
        SUM(oi.quantity) AS total_qty_sold,
        RANK() OVER (
            PARTITION BY p.category 
            ORDER BY SUM(oi.quantity) DESC
        ) AS rnk
    FROM products p
    JOIN order_items oi 
        ON p.product_id = oi.product_id
    GROUP BY p.category, p.product_name
)
SELECT 
    category,
    product_name,
    total_qty_sold
FROM product_sales
WHERE rnk = 1;

-- Q42 — Employees Who Share the Same Manager
-- Scenario: HR wants to group employees by their manager to review team sizes.
-- Expected Output columns: manager_name, team_size, team_members
SELECT 
    m.fullname AS manager_name,
    COUNT(e.emp_id) AS team_size,
    GROUP_CONCAT(e.fullname ORDER BY e.fullname SEPARATOR ', ') AS team_members
FROM employees e
JOIN employees m 
    ON e.manager_id = m.emp_id
GROUP BY m.fullname;

-- Q43 — Revenue Contribution Percentage per Product
-- Scenario: Management wants to see what percentage of total revenue each product contributes.
-- Expected Output columns: product_name, category, product_revenue, revenue_pct
SELECT 
    p.product_name,
    p.category,
    SUM(oi.quantity * oi.unit_price * (1 - oi.discount/100)) AS product_revenue,
    ROUND(
        SUM(oi.quantity * oi.unit_price * (1 - oi.discount/100)) * 100.0
        / SUM(SUM(oi.quantity * oi.unit_price * (1 - oi.discount/100))) OVER (),
    2) AS revenue_pct
FROM products p
JOIN order_items oi 
    ON p.product_id = oi.product_id
GROUP BY p.product_name, p.category;












