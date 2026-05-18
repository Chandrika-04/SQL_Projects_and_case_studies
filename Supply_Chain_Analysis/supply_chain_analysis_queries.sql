use supply_chain_analysis;

-- Q1 Total Orders by Status 

select order_status,count(order_id) as total_number_of_orders
from supply_chain_orders
group by order_status
order by count(order_id) desc;



-- Q2 Monthly Sales Trend  
-- Calculate the total sales and total orders for each month-year. Show months with the highest revenue at the top. 

select date_format(order_date,'%Y-%m') as order_month ,SUM(sales) as total_sales,count(order_id) as total_order
from supply_chain_orders
group by order_month
order by total_sales desc;


-- Q3 Top 10 Products by Revenue    
-- Find the top 10 products by total sales revenue. Include the product category and total units sold.

select product_name,category_name,SUM(sales) as total_revenue,SUM(order_item_quantity) as total_sold
from supply_chain_orders
group by product_name,category_name
order by total_revenue DESC
limit 10 ;


-- Q4 Customer Segment Analysis  
-- Calculate average order value, total sales, and order count for each customer segment. 
select customer_segment,
		SUM(sales) as total_revenue,
        avg(sales) as avg_order_value
from supply_chain_orders
group by customer_segment;


--  Q5 Late Delivery Rate by Shipping Mode    
-- Calculate the percentage of late deliveries for each shipping mode. Use the Late_delivery_risk flag. Which shipping mode has the worst performance? 

select shipping_mode,
		Count(*) as total_orders,
		(SUM(late_delivery_risk)*100)/count(*)  as pct_of_late_delivery
        from supply_chain_orders
        group by shipping_mode
        order by pct_of_late_delivery;
        
        
-- Q6 Average Lead Time per Category   
-- Compute the average actual shipping days vs. scheduled shipping days for each product 
-- category. Identify categories where actual time exceeds scheduled time the most.

select Category_name,
	   ROUND(avg(days_for_shipping_real),2) as avg_actual_days,
	   ROUND(AVG(days_for_shipment_scheduled),2) as avg_scheduled_days,
       ROUND(avg(days_for_shipping_real)-AVG(days_for_shipment_scheduled),2) as avg_delayed_days
from supply_chain_orders
group by category_name
order by avg_delayed_days;


-- Q7  Order Fill Rate by Region   
-- Find the fill rate (percentage of COMPLETE orders) for each Order Region. Rank the regions from best to worst performance. 

select order_region,count(*) as total_orders,
	   ROUND( SUM(case when order_status='complete'then 1 else 0 end ),2) as completed ,
       ROUND(100*( SUM(case when order_status='complete'then 1 else 0 end ))/count(*),2) as fill_rate_pct 
from supply_chain_orders
where order_status='Complete'
group by order_region
order by fill_rate_pct desc;
select order_item_discount from supply_chain_orders;


-- Q8 High-Discount Orders Impact 
-- Identify orders where the discount is greater than 20%. Calculate the average profit ratio for 
-- discounted vs. non-discounted orders. What pattern do you observe? 


select Case when order_item_discount>0.2 then 'High_discount (>20%)'
	   else 'Low_Discount (<20%)' end as discount_group,
       ROUND((avg(order_item_profit_ratio)*100)/count(*),2) as avg_profit_ratio
       from supply_chain_orders
       group by discount_group;
       
       
-- Q9 Rolling 3-Month Revenue  
-- Using a window function, calculate the 3-month rolling average of total revenue. This helps identify seasonal trends. 

with monthly_sales as (select date_format(order_date,'%Y-%m') as order_month,
		ROUND(SUM(sales),2) as monthly_revenue
        from supply_chain_orders
        group by order_month)
        select order_month,monthly_revenue,
        SUM(monthly_revenue) over (order by order_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) as month_rolling_avg
        from monthly_sales;
        
        
--  Q10 Rank Products Within Each Category   
-- Use RANK() or DENSE_RANK() to rank products by total sales within each category. Show only the top 3 products per category. 
with products_rank as(
	select category_name,product_name,SUM(sales) as total_sales,
    rank() over (partition by category_name order by sum(sales) desc) as sales_ranking
    from supply_chain_orders
    group by category_name,product_name)
    select category_name,product_name,total_sales,sales_ranking
    from products_rank
    where sales_ranking<=3;
    
    
-- Q11 Identify Repeat Late-Delivery Regions
-- Using a subquery or CTE, find all regions where late delivery rate exceeds the global average late delivery rate. Label them as underperforming regions. 
with region_stats as ( 
		select
		order_region,
        COUNT(*) AS total_orders, 
		ROUND(100.0 * SUM(Late_delivery_risk) / COUNT(*), 2) AS late_rate 
        FROM supply_chain_orders
        GROUP BY order_region 
), 
global_avg AS ( 
  SELECT ROUND(AVG(late_rate), 2) AS avg_late_rate FROM region_stats 
  group by order_region
) 
SELECT r.order_region, r.late_rate, 
       g.avg_late_rate, 
       'UNDERPERFORMING' AS status 
FROM region_stats r 
CROSS JOIN global_avg g 
WHERE r.late_rate > g.avg_late_rate 
ORDER BY r.late_rate DESC;

-- Q12 Customer Lifetime Value (CLV)  
-- Calculate the Customer Lifetime Value: total revenue, total orders, and average order value per 
-- customer. Rank customers by CLV and return the top 20.
with customer_clv as (select  customer_id,
		customer_segment,
		SUM(Sales) as total_revenue,Count(*) as total_orders,
		avg(sales) as avg_order_value
        from supply_chain_orders
        group by customer_id,customer_segment,customer_country)
        select customer_id,customer_segment,
        rank() over ( order by total_revenue desc) as clv_rank
        from customer_clv
        ORDER BY clv_rank 
        LIMIT 20; 
        
-- Q13 Supplier Performance Dashboard  
-- Design a query that produces a supplier/department-level performance dashboard including: 
-- total orders, total revenue, average late delivery rate, average profit ratio, and most popular shipping mode per department. 
WITH shipping_rank AS (
    SELECT department_name,shipping_mode,
        COUNT(*) AS shipping_count,
        RANK() OVER(PARTITION BY department_name ORDER BY COUNT(*) DESC) AS rn
    FROM supply_chain_orders
    GROUP BY department_name, shipping_mode
)
SELECT 
    s.department_name,
	COUNT(s.order_id) AS total_orders,
	ROUND(SUM(s.sales),2) AS total_revenue,
    ROUND(AVG(s.late_delivery_risk) * 100,2) AS avg_late_delivery_rate,
    ROUND(AVG(s.order_item_profit_ratio),2) AS avg_profit_ratio,
sr.shipping_mode AS most_popular_shipping_mode
FROM supply_chain_orders s
JOIN shipping_rank sr
ON s.department_name = sr.department_name
AND sr.rn = 1
GROUP BY s.department_name, sr.shipping_mode
ORDER BY total_revenue DESC;

--  Q14 Year-over-Year Sales Growth   
-- Calculate the year-over-year percentage change in total sales for each product category. Identify 
-- which categories are growing and which are declining. 
 with yoy_sales as (select category_name,
		Date_format(order_date,'%Y') as sales_year,
        Count(distinct order_id) as total_orders,
		SUM(sales) as total_sales 
        from supply_chain_orders
        group by category_name,sales_year
        order by total_sales)
        select category_name,sales_year,total_sales,
        LAG(total_sales) over (partition by category_name order by sales_year) as last_year_sales,
        Round(
        (total_sales-LAG(total_sales) over (partition by category_name order by sales_year))*100/
        LAG(total_sales) over (partition by category_name order by sales_year)
        ,2)as sales_percentage
        from yoy_sales;
        
--  Q15 Order Anomaly Detection    
-- Find orders where the actual shipping days exceed the scheduled days by more than 5 days AND the order is marked COMPLETE.
-- How many such anomalies exist, and which regions have the most? 
select order_region,count(*) as total_anomalies
		from supply_chain_orders
        where (days_for_shipping_real-days_for_shipment_scheduled)>5 and UPPER(order_status)='COMPLETE'
        group by order_region;        

-- Q16  Profitability by Geography   
-- Write a query that shows total revenue, total profit (Sales * Order Item Profit Ratio), and profit 
-- margin percentage by Order Country. Filter to countries with more than 500 orders.
select order_country,count(*) as total_orders ,sum(sales) as total_revenue,
		ROUND(SUM(Sales * Order_Item_Profit_Ratio),2) as total_profit,
        ROUND(
        (SUM(sales * order_item_profit_ratio) / SUM(sales)) * 100,
    2) AS profit_margin_percentage
        from supply_chain_orders
        group by order_country,order_city
        having count(*)>500;
        