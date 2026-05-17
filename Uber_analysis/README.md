# 🚗 Uber SQL Capstone Project

> **Course:** SQL for Data Analysis  
> **Domain:** Ride-Sharing Operations  
> **Database:** `uber` (MySQL)

A comprehensive SQL case study simulating real-world data analysis for a ride-sharing platform. The project covers the full analytics workflow — from data cleaning to advanced query optimization — using a multi-table relational database modeled after Uber's core operations.

---

## 📁 Database Schema

| Table | Key Columns |
|---|---|
| `rides` | ride_id, start_city, end_city, ride_date, start_time, end_time, distance_km, fare, dynamic_pricing, driver_id, passenger_id, rating, payment_method, ride_status |
| `drivers` | driver_id, driver_name, age, gender, city_id, vehicle_type, avg_driver_rating, total_rides, total_earnings, driver_status, employment_type, years_of_experience, ride_acceptance_rate |
| `payments` | payment_id, ride_id, driver_id, passenger_id, fare, surge_multiplier, payment_method, driver_earnings, uber_commission, transaction_status, payment_date |
| `cities` | city_id, city_name, country, continent, population, regulatory_status, market_competition, number_of_drivers, number_of_rides, avg_fare, avg_wait_time_min, uber_services, major_competitors |

---

## 🧹 Data Cleaning

Before any analysis, the data is cleaned across four steps:

1. **Remove Duplicate Rides** — Identifies and deletes duplicate `ride_id` rows using a self-join, keeping the first occurrence. Prevents inflated revenue totals and distorted driver metrics.

2. **Handle Missing Fares** — Detects NULL or zero fares and replaces them with the city-level average fare using a correlated subquery. Ensures revenue calculations remain valid.

3. **Handle Missing Population in Cities** — Fills NULL population values using the average population of the same continent — a context-aware imputation strategy.

4. **Validate Ride Status Values** — Normalizes inconsistent casing and typos (e.g., `"cancelled"` → `"Canceled"`, `"done"` → `"Completed"`) to enforce consistent categorical values.

> ⚠️ All `UPDATE` and `DELETE` statements are wrapped with `SET SQL_SAFE_UPDATES = 0/1` to safely run in MySQL Workbench's safe mode.

---

## ❓ Analysis Questions

### Q1 — City-Level Performance Optimization
**Which are the top 3 cities where Uber should focus on driver recruitment?**

Builds a **composite recruitment score** combining:
- High demand (total rides)
- High cancellation rate (rides lost due to supply shortage)
- Low average driver rating (service quality issues)

Cities scoring highest on all three signals are flagged as understaffed.

---

### Q2 — Revenue Leakage Analysis
**How can rides with fare discrepancies or missing payments be detected?**

Identifies two types of revenue leakage:
- **Missing Payment** — Completed rides with no corresponding record in the `payments` table (LEFT JOIN + NULL check)
- **Fare Mismatch** — Rides where the fare in `rides` differs from `payments` by more than ₹1 (tolerance for rounding errors)

Includes a summary query to quantify total estimated revenue lost by leak type.

---

### Q3 — Cancellation Analysis
**What are the cancellation patterns across cities, and how do they correlate with revenue?**

For each city, calculates:
- Total, canceled, and completed ride counts
- Cancellation rate (%)
- Actual revenue earned from completed rides
- Estimated revenue lost from cancellations (canceled count × avg completed fare)

Cities with high cancellation rate AND high revenue loss are prioritized for operational intervention.

---

### Q4 — Cancellation Patterns by Time of Day
**Which hours have the highest cancellation rates, and what is their impact on revenue?**

Extracts the hour from `start_time` and groups rides into four periods: Morning, Afternoon, Evening, and Night. Reveals rush-hour driver shortages and late-night supply gaps.

| Time Period | Likely Cause | Recommended Action |
|---|---|---|
| Morning peak | Driver shortage during rush hour | Surge pricing + driver incentives |
| Late night | Safety concerns, low supply | Bonus pay for night drivers |
| Afternoon | Often weather-related | Monitor seasonally |

---

### Q5 — Seasonal Fare Variations
**How do fare amounts vary across seasons? Are there anomalies?**

Maps `ride_date` months to seasons (Northern Hemisphere) and compares:
- Average, min, and max fare per season
- Fare standard deviation (high = erratic pricing / anomaly signal)
- Dynamic pricing usage rate (%)

---

### Q6 — Average Ride Duration by City
**What is the average ride duration per city, and how does it relate to satisfaction?**

Calculates duration using `TIMESTAMPDIFF` with a `MOD + 1440` trick to correctly handle overnight rides that cross midnight. Joins with ratings to explore the duration–satisfaction relationship and computes `fare_per_minute` as a profitability metric.

---

### Q7 — Index for Ride Date Performance
**How can query performance be improved when filtering rides by date?**

Creates a single-column index `idx_ride_date` and a composite index `idx_ride_date_city` for queries that filter by both date and city. Demonstrates how to verify index usage with `EXPLAIN`.

---

### Q8 — View for Average Fare by City
**How can city-level fare statistics be accessed quickly without rewriting complex joins?**

Creates a reusable VIEW `vw_avg_fare_by_city` that joins `rides` and `cities`, exposing avg/min/max fare, passenger ratings, wait times, and market competition level.

**Benefits of Views:**

| Benefit | Description |
|---|---|
| Simplicity | Hides complex joins behind a clean interface |
| Reusability | Used across reports, dashboards, and apps |
| Security | Exposes only the columns needed |
| Always fresh | Reflects the latest data — no stale snapshots |

---

### Q9 — Trigger for Ride Status Change Logging
**How can changes to ride statuses be tracked for auditing?**

Creates an audit system in two steps:
1. A `ride_status_log` table to store change history
2. An `AFTER UPDATE` trigger `trg_ride_status_change` that fires automatically whenever `ride_status` changes — logging the old value, new value, timestamp, and database user

```
rides table
  ↓ UPDATE ride_status
  ↓
[TRIGGER fires automatically]
  ↓
ride_status_log → ride_id | old_status | new_status | timestamp
```

---

### Q10 — View for Driver Performance Metrics
**What metrics best assess overall driver efficiency?**

Creates `vw_driver_performance` — a comprehensive view combining stored driver data with live ride history:
- Stored metrics: `avg_driver_rating`, `total_earnings`, `ride_acceptance_rate`
- Live metrics: `actual_ride_count`, `live_avg_passenger_rating`, `completion_rate_pct`, `avg_fare_per_completed_ride`

Includes ready-to-use queries for finding top earners and underperforming drivers.

---

### Q11 — Index on Payment Method
**How can payment-related queries be optimized?**

Creates targeted indexes on the `payments` table:
- `idx_payment_method` — for queries grouping by payment type
- `idx_transaction_status` — for filtering by transaction outcome
- `idx_payment_method_status` — composite index for queries filtering both simultaneously

Demonstrates verification using `EXPLAIN` and explains what to look for (`type: ref` = good, `type: ALL` = full scan = bad).

---

## 🗂 Database Objects Created

| Object | Type | Purpose |
|---|---|---|
| `idx_ride_date` | Index | Faster date-range filtering on rides |
| `idx_ride_date_city` | Index | Composite index for date + city filters |
| `idx_payment_method` | Index | Faster payment method grouping |
| `idx_payment_method_status` | Index | Composite index for payment queries |
| `vw_avg_fare_by_city` | View | Quick access to city-level fare stats |
| `vw_driver_performance` | View | Comprehensive driver efficiency metrics |
| `trg_ride_status_change` | Trigger | Audit log for ride status changes |
| `ride_status_log` | Table | Stores all ride status change history |

---

## 🛠 How to Run

1. **Set up MySQL** (MySQL 8.0+ recommended) and open MySQL Workbench or any MySQL client.
2. **Create the database** and import the schema + seed data.
3. **Run Data Cleaning** scripts first (Steps 1–4) before executing any analysis queries.
4. **Execute questions** in order (Q1–Q11). Each section is self-contained with comments explaining the logic.
5. Use `EXPLAIN` to verify indexes are being picked up by the query planner.

---

## 💡 Key Concepts Covered

- `JOIN`, `LEFT JOIN`, `UNION ALL`
- `GROUP BY`, `HAVING`, `CASE WHEN`
- Window functions and subqueries
- `TIMESTAMPDIFF` for time-based calculations
- `STDDEV` for anomaly detection
- Creating and using **VIEWs**
- Creating **INDEXes** (single-column and composite)
- Writing **TRIGGERs** for audit logging
- Safe update mode handling in MySQL Workbench
- `EXPLAIN` for query plan analysis

---

## 📄 License

This project is intended for educational purposes as part of a SQL for Data Analysis course.
