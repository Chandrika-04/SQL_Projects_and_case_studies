Use Uber_analysis;
SET SQL_SAFE_UPDATES=1;

ALTER TABLE city_dataset2 rename to city;
ALTER TABLE driver_dataset3 rename to drivers;
ALTER TABLE rides_dataset1 rename to rides;
RENAME TABLE `payment_dataset 4` TO payments;

-- Data cleaning

-- Finding duplicate rides
select ride_id,count(*) as occurances
from rides_dataset1
group by ride_id
having count(*)>1;

SET SQL_SAFE_UPDATES=0;

-- deleting duplicate ride_id from rides
DELETE r1
FROM rides r1
JOIN rides r2
ON r1.ride_id = r2.ride_id
AND r1.ride_id > r2.ride_id;

 -- deleting the blank and null ids from rides
DELETE FROM rides
WHERE ride_id IS NULL
OR TRIM(ride_id) = '';
select * from rides;

-- handling missing fares
select count(*) as missing_fares
from rides 
where fare is NULL or fare=0;

SET SQL_SAFE_UPDATES = 0;

update rides r
JOIN( select start_city,avg(fare) as avg_fare
	  from rides
      where fare IS NOT NULL and fare > 0
	  group by start_city) city_avg
	   on r.start_city = city_avg.start_city
       set r.fare = city_avg.avg_fare
       where r.fare IS NULL OR r.fare = 0;

--  Handle Missing Population in Cities
select count(*) as missing_population
from city
where population is null or population =0;

-- updating the missing population with avg_population
update city c
join(select continent,avg(population) as avg_population
	 from city
     where population is not null or population =0
     group by continent )population_avg
     on c.continent=population_avg.continent
     set c.population=population_avg.avg_population
     where c.population is NULL or c.population = 0;
     
-- Check for unexpected ride_status values (safe read — no guard needed)
select distinct ride_status
from rides;

SET SQL_SAFE_UPDATES = 0;


-- 1.City-Level Performance Optimization
------------------------------------------------------------------------------------------------------
-- Which are the top 3 cities where Uber should focus more on driver recruitment based on demand, high
-- cancellation rates, and driver ratings?
-- ---------------------------------------------------------------------------------------------------
select start_city,count(*) as total_rides,
	   ROUND(SUM(case when ride_status='Canceled' then 1 else 0 end) * 100 / count(*) ,2) as cancellation_rate_pct,
       AVG(rating) as average_rating,
       ROUND(
       (SUM(case when ride_status='Canceled' then 1 else 0 end) * 100 / count(*))+ (COUNT(*) / 100.0) - AVG(rating)
       ,2) as  recruitment_score
       from rides
       group by start_city
       order by recruitment_score desc
       LIMIT 3;
       
       
--  2. Revenue Leakage Analysis
-------------------------------------------------------------------------------------------------------------------------
-- How can you detect rides with fare discrepancies or those marked as "completed" without any corresponding payment?
/* Revenue leaks in two ways:
A ride is Completed but has no payment record at all
The fare in rides doesn't match the fare in payments */
--------------------------------------------------------------------------------------------------------------------------
select leakage_type,
		count(*) as num_of_rides,
        ROUND(SUM(ride_fare),2) as estimated_fare
from(
	select r.ride_id,r.fare as ride_fare, ' Missing Payment' as leakage_type
	from rides r left join payments p 
	on r.ride_id = p.ride_id
	where r.ride_status='Completed' and p.payment_id IS NULL
	UNION ALL
	select r.ride_id,r.fare as ride_fare, ' Fare Mismatch ' as leakage_type
	from rides r  join payments p 
	on r.ride_id = p.ride_id
	where r.ride_status='Completed' and ABS(r.fare - p.fare) > 1.0
    )leak
    group by leakage_type;


--  3.Cancellation Analysis
-----------------------------------------------------------------------------------------------------------------------
-- What are the cancellation patterns across cities? How do these correlate with revenue from completed rides?
/* For each city we want:
How many rides were canceled vs completed
What revenue was earned from completed rides
What potential revenue was lost due to cancellations (estimated using avg fare) */
--------------------------------------------------------------------------------------------------------------------------


select start_city,
	   count(*) as total_rides,
	   SUM(case when ride_status='Completed'then 1 else 0 end) as completed_rides,
       SUM(case when ride_status='Canceled'then 1 else 0 end) as cancelled_rides,
		ROUND(
           (SUM(case when ride_status='Canceled'then 1 else 0 end) *100)/count(*) 
           ,2) as cancelled_pct_rate,
         ROUND(
           (SUM(case when ride_status='Completed'then fare else 0 end))
           ,2) as revenue_earned,  
		 ROUND(
			(SUM(case when ride_status='Canceled'then 1 else 0 end))*
            (avg(case when ride_status='Completed'then fare else 0 end))
		 ,2) as estimated_revenue_lost
from rides 
group by start_city
order by cancelled_pct_rate desc;


--  4.Cancellation Patterns by Time of Day
---------------------------------------------------------------------------------------------------------------------------------
 -- Which hours have the highest cancellation rates, and what is their impact on revenue?
 -- We extract the hour from start_time and group rides by it. This reveals rush-hour problems or late-night supply gaps.
 ------------------------------------------------------------------------------------------------------------------------------
 
 select start_time as ride_hour,
		case 
			when HOUR(start_time) between 6 and 11 then 'Morning (6 am -11 am)'
            when HOUR(start_time) between 12 and 16 then 'Afternoon (12 pm -5 pm)'
            when HOUR(start_time) between 17 and 20 then 'Evening   (5pm–9pm)'
            ELSE 'Night(9pm–6am)' END as time_period,
		count(*) as num_of_rides,
        SUM(CASE WHEN ride_status = 'Canceled' THEN 1 ELSE 0 END) AS canceled,
        ROUND(
           (SUM(case when ride_status='Canceled'then 1 else 0 end) *100)/count(*) 
           ,2) as cancelled_pct_rate,
		SUM(CASE WHEN ride_status = 'Canceled' THEN fare ELSE 0 END) AS revenue_loss
from rides
group by ride_hour,time_period
order by cancelled_pct_rate;

-- 5. Seasonal Fare Variations
-----------------------------------------------------------------------------------------------------------------------------
/* How do fare amounts vary across different seasons? Identify significant trends or anomalies.
 We map ride_date months to seasons (Northern Hemisphere convention), then compare average fares, ride counts, and dynamic
 pricing usage per season. */
-------------------------------------------------------------------------------------------------------------------------------


select 
	case when month(ride_date) IN(12,1,2) then 'Winter'
		 when month(ride_date) IN(3,4,5) then 'Spring'
         when month(ride_date) IN(6,7,8) then 'Summer'
         else 'Autumn'
         end  as season,
	COUNT(*) as total_rides,
	ROUND(MIN(fare),2) as mimnimun_fare,
    ROUND(MAX(fare),2) as maximum_fare,
    ROUND(AVG(fare),2) as avg_fare,
    ROUND(stddev(fare)) as std_fare,
    ROUND(
     (SUM(case when dynamic_pricing='Yes' then 1 else 0 end ))/count(*)
     ,2) as dynamic_pricing_pct
     from rides
     group by season
     order by avg_fare desc;
     
-- 6.Average Ride Duration by City
-------------------------------------------------------------------------------------------------------------------------
/* What is the average ride duration for each city? How does this relate to customer satisfaction?
We calculate duration by finding the difference between end_time and start_time. We then join with average ratings to see i
longer rides correlate with lower satisfaction.*/


select  start_city as city,
		count(*) as total_rides,
        ROUND(
          AVG(MOD(TIMESTAMPDIFF(minute,CONCAT('2000-01-01 ', start_time),CONCAT('2000-01-01 ', end_time))+1440,1400))
          ,2) as avg_duration_minute,
		ROUND(avg(fare),2)  as avg_fare,
        ROUND(AVG(rating),2) as avg_rating,
        ROUND(avg(fare)/NULLIF(
          AVG(MOD(TIMESTAMPDIFF(minute,CONCAT('2000-01-01 ', start_time),CONCAT('2000-01-01 ', end_time))+1440,1400)),0)
          ,2) as fare_per_minute
from rides
where ride_status='Completed'
group by start_city
order by avg_duration_minute desc;

-- 7.Index for Ride Date Performance
--------------------------------------------------------------------------------------------------------------------------------
/* How can query performance be improved when filtering rides by date
Without an index, MySQL performs a full table scan on every query that filters by ride_date — reading every single row even if
you only need rides from one month. An index is like a sorted lookup table that lets MySQL jump directly to the relevant rows.*/
---------------------------------------------------------------------------------------------------------------------------------

-- check if there is index present in rides
show index from rides;

-- create single column index for ride date
create index idx_ride_date ON rides(ride_date);

create index idx_ride_date_city ON rides(ride_date,start_city);

-- Verify the index is being used
EXPLAIN
SELECT * FROM rides
WHERE ride_date BETWEEN '2024-01-01' AND '2024-03-31';

--  8.View for Average Fare by City
----------------------------------------------------------------------------------------------------------------------------
/* How can you quickly access information on average fares for each city?
A VIEW is a saved SQL query that behaves like a virtual table. Instead of writing the same complex query every time, you query
the view with a simple SELECT. The underlying data stays live — the view always reflects current data.*/
-----------------------------------------------------------------------------------------------------------------------------

create view vw_avg_fare_by_city as ( 
	select r.start_city as city,
    count(*) as total_rides,
    ROUND(min(r.fare)) as min_fare,
    ROUND(max(r.fare)) as max_fare,
    ROUND(avg(r.fare)) as avg_fare,
    ROUND(c.avg_wait_time_min) as avg_waiting_time,
    c.market_competition
from rides r join city c
on r.start_city=c.city_name
where r.ride_status='Completed'
GROUP BY r.start_city, c.avg_wait_time_min, c.market_competition);

SELECT * FROM vw_avg_fare_by_city
ORDER BY avg_fare DESC;

SELECT city, avg_fare
FROM vw_avg_fare_by_city
WHERE market_competition = 'High';

-- 9.Trigger for Ride Status Change Logging
----------------------------------------------------------------------------------------------------------------------------------
/*  How can you track changes in ride statuses for auditing purposes?
A TRIGGER is a procedure that MySQL runs automatically when a specific event (INSERT / UPDATE / DELETE) happens on a table.
Here, we want to log every time a ride's status is updated — who changed it, from what, to what, and when */
-----------------------------------------------------------------------------------------------------------------------------------

-- Step 1 — Create the Audit Log Table
create table if not exists ride_status_log(
log_id int auto_increment primary key,
ride_id VARCHAR(50) NOT NULL,
old_status VARCHAR(30),
new_status VARCHAR(30),
changed_at datetime default current_timestamp,
changed_by varchar(100) 
);
-- creating trigger
DELIMITER $$
CREATE trigger trg_ride_status_change
AFTER update on rides
FOR each row
begin
IF OLD.ride_status <> NEW.ride_status THEN
	INSERT INTO ride_status_log (ride_id, old_status, new_status)
	VALUES (NEW.ride_id, OLD.ride_status, NEW.ride_status);
END IF;
END$$
DELIMITER ;

-- Testing the trigger
SET SQL_SAFE_UPDATES = 0;

UPDATE rides
SET ride_status = 'Completed'
WHERE ride_id = 'b26d2384-e990-4269-a1b7-6c6e433cfc1d';
SET SQL_SAFE_UPDATES = 1;

-- changing  the status to check wether the trigger is working
UPDATE rides
SET ride_status = 'Canceled'
WHERE ride_id = 'b26d2384-e990-4269-a1b7-6c6e433cfc1d';
    
-- Check the audit log
SELECT * FROM ride_status_log
ORDER BY changed_at DESC
LIMIT 10;

-- 10. View for Driver Performance Metrics
-----------------------------------------------------------------------------------------------------------------------------------
/* What performance metrics can be summarized to assess driver efficiency?
A driver performance view should combine data from both the drivers table (stored totals) and the live rides table (actual ride
history), so managers get a complete, up-to-date picture.*/
------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE VIEW  vw_driver_performance   as 
select d.driver_id,
	   d.driver_name,
       d.vehicle_type,
       d.driver_status,
       d.employment_type,
       d.years_of_experience,
       d.Avg_driver_rating  as avg_driver_rating,
       d.total_rides as total_rides,
       ROUND(d.total_earnings,2) as total_earnings,
       ROUND(d.ride_acceptance_rate, 2) as acceptance_rate_pct,
       COUNT(r.ride_id) as  actual_ride_count,
       ROUND(AVG(r.rating), 2) as live_avg_passenger_rating,
       SUM(CASE WHEN ride_status = 'Completed' THEN 1 ELSE 0 END) AS completed_rides,

SUM(CASE WHEN ride_status = 'Canceled' THEN 1 ELSE 0 END) AS canceled_rides,

ROUND(
(
    SUM(CASE WHEN ride_status = 'Completed' THEN 1 ELSE 0 END) * 100.0
) / NULLIF(COUNT(r.ride_id), 0),
2
) AS completion_rate_pct,

ROUND(
SUM(CASE WHEN ride_status = 'Completed' THEN fare ELSE 0 END) /
NULLIF(
    SUM(CASE WHEN ride_status = 'Completed' THEN 1 ELSE 0 END),
    0
),
2
) AS avg_fare_per_completed_ride
FROM drivers d
left JOIN rides r ON d.driver_id = r.driver_id
GROUP BY d.driver_id, d.driver_name, d.vehicle_type, d.driver_status,
d.employment_type, d.years_of_experience, d.avg_driver_rating,
d.total_rides, d.total_earnings, d.ride_acceptance_rate;
       
SELECT driver_name, total_earnings, completion_rate_pct, live_avg_passenger_rating
FROM vw_driver_performance
WHERE driver_status = 'Active'
ORDER BY total_earnings DESC
LIMIT 10;

-- 11. Index on Payment Method for Faster Querying
-------------------------------------------------------------------------------------------------------------------------------
/*Queries that filter or group by payment_method (e.g., "show all Cash payments", "total revenue by payment type") scan the entire
payments table without an index. Since payment_method has low cardinality (few unique values like Cash, Credit Card, UPI), MySQL
can use an index very effectively here.*/
---------------------------------------------------------------------------------------------------------------------------------

-- Create index on payment_method in the payments table
CREATE INDEX idx_payment_method
ON payments(payment_method);
-- Also useful: index on transaction_status (often filtered together)
CREATE INDEX idx_transaction_status
ON payments(transaction_status);
-- Composite index for queries that filter BOTH at once
CREATE INDEX idx_payment_method_status
ON payments(payment_method, transaction_status);

-- Before index: full table scan-- After index:  index range scan (much faster on large tables)
SELECT payment_method,
	   COUNT(*) AS total_transactions,
	   ROUND(SUM(fare), 2) AS total_revenue,
       ROUND(AVG(fare), 2)  AS avg_fare,
	   SUM(CASE WHEN transaction_status = 'Failed' THEN 1 ELSE 0 END) AS failed_transactions
FROM payments
GROUP BY payment_method
ORDER BY total_revenue DESC;

EXPLAIN
SELECT * FROM payments
WHERE payment_method = 'Cash'
AND transaction_status = 'Completed';
