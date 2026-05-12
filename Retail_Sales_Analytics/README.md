# 🛒 RetailPulse Analytics — SQL Data Challenge

> **"From Raw Records to Real Insights"**  
> A complete end-to-end SQL project built on a simulated Indian retail chain's transactional database — covering schema design, data manipulation, business reporting, and advanced analytical queries.

---

## 📌 Project Overview

**RetailPulse Inc.** is a mid-sized e-commerce and brick-and-mortar retail chain operating across India. This project simulates the role of a **Data Analyst** who has just received migrated transactional data and must build the entire analytical foundation from scratch.

The challenge is structured into **5 progressive phases**, each building on the last — from creating tables to writing executive-level business intelligence reports using window functions.

**Environment:** `MySQL 8.0` | `MySQL Workbench`

---

## 🗂️ Repository Structure

```
RetailPulse-SQL-Analytics/
│
├── retail_sales.sql                 ← Database schema + all seed data (DDL + INSERT)
├── retail_sales_analytics.sql       ← All 5 phases of analytical queries
└── README.md                        ← You are here
```

---

## 🗃️ Database Schema

The database consists of **6 interrelated tables:**

```
customers
    │
    │ customer_id
    ▼
orders ──────────────────────────► returns
    │                                  │
    │ order_id                          │ product_id
    ▼                                  ▼
order_items ────────────────────► products
                product_id             │
                                       │ category_id
                                       ▼
                                   categories
                               (self-referencing via parent_id)
```

| Table | Description |
|---|---|
| `customers` | Customer profiles, city, state, loyalty tier |
| `categories` | Hierarchical product categories (parent-child) |
| `products` | Product catalog with pricing, stock, supplier |
| `orders` | Orders with status, channel (Online/In-Store) |
| `order_items` | Line items per order with quantity and discount |
| `returns` | Product return records with reason and refund |

---

## 📚 Topics Covered

| Phase | Topics |
|---|---|
| **Phase 1** — Schema Architect | `CREATE TABLE`, `ALTER TABLE`, `DROP`, `INSERT`, `UPDATE`, `DELETE`, Constraints, CHECK, UNIQUE, Foreign Keys |
| **Phase 2** — The Query Engine | Aggregate Functions, `GROUP BY`, `HAVING`, `ORDER BY`, String Functions, Date-Time Functions, Regular Expressions |
| **Phase 3** — Joins, Views & CTEs | `INNER JOIN`, `LEFT JOIN`, Self-Join, Multi-table Join, Nested Queries, Recursive CTEs, Views, Set Operations (`UNION`, `INTERSECT`, `EXCEPT`) |
| **Phase 4** — Window Functions | `RANK()`, `DENSE_RANK()`, `ROW_NUMBER()`, `NTILE()`, `PERCENT_RANK()`, Partitioning, Named Windows, ROWS/RANGE Frames, `LAG()`, `LEAD()`, `FIRST_VALUE()`, `LAST_VALUE()` |
| **Phase 5** — Dashboard Report | Full integration — CLV Report, Product Health Dashboard, Channel & Coupon Analysis, Purchase Trajectory, Cohort Analysis |

---

## 🚀 How to Run

1. Open **MySQL Workbench** and connect to your local MySQL 8.0 instance
2. Run `retail_sales.sql` first — this creates the database, all tables, and inserts seed data
3. Run `retail_sales_analytics.sql` — execute phase by phase or run all at once

```sql
-- Start here
CREATE DATABASE IF NOT EXISTS retailpulse;
USE retailpulse;
-- Then run the rest of retail_sales.sql
```

> ⚠️ Run tables in this order to respect foreign key dependencies:
> `customers` → `categories` → `products` → `orders` → `order_items` → `returns`

---

## 📋 Phase-by-Phase Breakdown

---

### 🔧 Phase 1 — Schema Architect

**Goal:** Build the database warehouse before any analysis can happen.

---

#### Task 1.1 — Design a New Table

**Q:** Create a `product_reviews` table with the following rules:
- Linked to one customer and one product via foreign keys
- `rating` is mandatory, integer only, values 1–5 (CHECK constraint)
- `review_text` is optional (nullable)
- `review_date` is mandatory
- A customer can review the same product only once (composite UNIQUE)
- `verified_purchase` defaults to 0 (FALSE)

**Approach:** Used `CHECK (rating BETWEEN 1 AND 5)` for range validation and a composite `UNIQUE (customer_id, product_id)` constraint to prevent duplicate reviews.

```sql
CREATE TABLE product_reviews (
    review_id         INT          PRIMARY KEY AUTO_INCREMENT,
    customer_id       INT          NOT NULL,
    product_id        INT          NOT NULL,
    rating            INT          NOT NULL,
    review_text       TEXT,
    review_date       DATE         NOT NULL,
    verified_purchase TINYINT(1)   DEFAULT 0,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (product_id)  REFERENCES products(product_id),
    CONSTRAINT chk_rating      CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT uq_cust_product UNIQUE (customer_id, product_id)
);
```

---

#### Task 1.2 — Alter and Evolve the Schema

**Q:** Apply the following structural changes to the schema:
1. Add optional `gstn_number VARCHAR(20)` to `customers`
2. Rename `loyalty_tier` to `membership_tier`
3. Increase `phone` from `VARCHAR(15)` to `VARCHAR(20)`
4. Replace NULL `supplier` values with `'Unknown Supplier'`, then enforce `NOT NULL`
5. Drop `coupon_code` from `orders`

**Approach:** Each change uses a targeted `ALTER TABLE` statement. For the `NOT NULL` constraint, an `UPDATE` must run first to eliminate existing NULLs — otherwise the constraint addition fails.

```sql
ALTER TABLE customers ADD COLUMN gstn_number VARCHAR(20) NULL;
ALTER TABLE customers RENAME COLUMN loyalty_tier TO membership_tier;
ALTER TABLE customers MODIFY COLUMN phone VARCHAR(20);

UPDATE products SET supplier = 'Unknown Supplier' WHERE supplier IS NULL;
ALTER TABLE products MODIFY COLUMN supplier VARCHAR(100) NOT NULL;

ALTER TABLE orders DROP COLUMN coupon_code;
```

---

#### Task 1.3 — DML: Data Corrections

**Q:** Fix the following data quality issues:
1. Update Nikhil Bose's email to `nikhil@mail.com`
2. Move Order 1009 to status `'Shipped'`
3. Add 300 units to Product 108's stock
4. Correct `item_id = 2` quantity from 3 to 5
5. Delete all returns with reason `'Changed mind'`

**Approach:** Targeted `UPDATE` and `DELETE` statements using primary key filters to avoid accidental bulk changes.

---

### 🔍 Phase 2 — The Query Engine

**Goal:** Turn raw rows into business intelligence.

---

#### Task 2.1 — Aggregate Functions and Ordering

**Q1:** Total revenue per category (excluding cancelled orders), ordered highest to lowest.  
**Approach:** `SUM(quantity * unit_price * (1 - discount_pct/100))` joined across `order_items → products → categories`, filtered with `WHERE status <> 'Cancelled'`.

**Q2:** Average order value per channel (Online vs In-Store) for Delivered orders only.  
**Approach:** Revenue divided by `COUNT(DISTINCT order_id)` grouped by `channel`.

**Q3:** Customers with more than 2 delivered orders — name, city, count.  
**Approach:** `HAVING COUNT(order_id) > 2` on a join between `customers` and `orders`.

**Q4:** Top 3 products by total units sold across non-cancelled orders.  
**Approach:** `SUM(quantity)` grouped by product, filtered by status, `ORDER BY ... LIMIT 3`.

**Q5:** Count of customers who used a coupon + orders with vs without coupon in one query.  
**Approach:** Conditional aggregation using `SUM(CASE WHEN coupon_code IS NOT NULL THEN 1 ELSE 0 END)`.

---

#### Task 2.2 — The HAVING Clause

**Q1:** Categories where average listed unit price > ₹10,000.

**Q2:** Suppliers who supply more than one product.

**Q3:** Months in 2023 where total Delivered orders exceeded 2, displayed as `YYYY-MM`.

**Q4:** Customers whose total refund amount exceeds ₹50,000

---

#### Task 2.3 — String Functions

**Q1:** Extract first name and last name from `full_name` into separate columns.

**Q2:** Build a display label formatted as `ARYAN M. | Gold | Mumbai`.

**Q3:** Extract email domain (part after `@`) for customers with an email.

**Q4:** Products whose name exceeds 20 characters, ordered by length descending.

**Q5:** Display all city values in proper Title Case (SELECT only, not UPDATE).

---

#### Task 2.4 — Date and Time Functions

**Q1:** Days each customer has been registered as of today.

**Q2:** Full month name for each Delivered order using `MONTHNAME()`.

**Q3:** All orders placed in Q1 2023 (January–March).

**Q4:** Days gap between order date and return date — flagged as `'Late Return'` (>15 days) or `'Within Window'`.

**Q5:** Most recent order, earliest order, and the difference in days — in one query.

---

#### Task 2.5 — Regular Expressions

**Q1:** Customers with potentially invalid/missing-domain emails.

**Q2:** Products whose name does not start with an uppercase A–Z letter.

**Q3:** Customers with invalid Indian mobile numbers (must start with 6–9, 10 digits total).

**Q4:** Remove digits from product names using `REGEXP_REPLACE` — original vs cleaned side by side.

**Q5:** Extract the 4-digit year from `added_on` using `REGEXP_SUBSTR`.


---

### 🔗 Phase 3 — Joins, Set Theory, Views, and CTEs

**Goal:** Combine the pieces — the real world is never just one table.

---

#### Task 3.1 — Nested Queries and CTEs

**Q1:** Products never ordered — using a `NOT IN` subquery on `order_items`.

**Q2:** Customers with above-average total spend on delivered orders — using a CTE.  
**Approach:** First CTE calculates per-customer spend, outer query filters where `total_spend > AVG(total_spend)` from the same CTE.

**Q3:** Full category hierarchy using a **Recursive CTE**.  
**Approach:** Anchor selects top-level categories (`parent_id IS NULL`), recursive member joins children to parents until no more levels remain.

**Q4:** Each customer's most recent order using a **correlated subquery** referencing the outer `customer_id`.

**Q5:** Slow-moving products (units sold below average) using a CTE.

---

#### Task 3.2 — Types of Joins

| Join Type | Question |
|---|---|
| `INNER JOIN` | All order items with product name, category, and customer name |
| `LEFT JOIN` | Every customer with total order count (zero-order customers show 0) |
| `LEFT JOIN + NULL filter` | Products never ordered (simulates NOT IN) |
| `Self-Join` | Product pairs in the same category with price difference > ₹50,000 |
| Multi-table Join | Every return with customer, product, reason, refund, and purchase channel |
| Outer Join + `CASE WHEN` | Label each customer as `'Has Orders'` or `'No Orders'` |

---

#### Task 3.3 — Views

**`vw_customer_order_summary`** — per-customer order stats and revenue  
**`vw_product_performance`** — per-product sales, revenue, return count  
**`vw_monthly_sales`** — monthly revenue aggregated in `YYYY-MM` format

> 💡 **Can you UPDATE/DELETE through `vw_customer_order_summary`?**  
> **No.** MySQL does not allow DML through views that use aggregate functions, `GROUP BY`, or multi-table joins. Attempting it returns `ERROR 1288: The target table is not updatable`.

---

#### Task 3.4 — Set Operations

| Operation | Question |
|---|---|
| `UNION` | All distinct cities from customers OR warehouse list |
| `INTERSECT` (simulated) | Cities that exist in BOTH customers and warehouse list |
| `EXCEPT` (simulated) | Warehouse cities with NO registered customers |
| `UNION` vs `UNION ALL` | Row count comparison + explanation of when to use each |

> 💡 **UNION vs UNION ALL:**  
> `UNION` removes duplicates (slower). `UNION ALL` keeps all rows (faster). Use `UNION` for distinct lists, `UNION ALL` for counting all occurrences.

---

### 🪟 Phase 4 — Window Functions Masterclass

**Goal:** Analyse without collapsing rows — the power of analytical SQL.

---

#### Task 4.1 — Rank Functions

**Q1:** Rank customers by total revenue using `RANK()`, `DENSE_RANK()`, and `ROW_NUMBER()` side by side.

> 💡 **When they differ:** If two customers tie at rank 1,  
> `RANK()` → 1, 1, 3 (skips rank 2)  
> `DENSE_RANK()` → 1, 1, 2 (no gap)  
> `ROW_NUMBER()` → 1, 2, 3 (no ties, arbitrary for equals)

**Q2:** Top 2 products by revenue within each category using `DENSE_RANK() OVER (PARTITION BY category_id)`.

**Q3:** Sequential purchase number per customer using `ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date)`.

**Q4:** Divide customers into spending quartiles Q1–Q4 using `NTILE(4)` with `CASE WHEN` labels.

---

#### Task 4.2 — Partitioning and Named Windows

**Q1:** Each line item's revenue as a % of its category's total — using `SUM() OVER (PARTITION BY category_id)`.

**Q2:** Running cumulative total and running average revenue per customer using:
```sql
SUM(order_revenue) OVER (
    PARTITION BY customer_id ORDER BY order_date
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
)
```

**Q3:** Named window `w_customer` reused across `ROW_NUMBER()`, `SUM()`, and `AVG()` in a single query using the `WINDOW` clause.

**Q4:** Compare min/max price from `order_items` against listed price — labelled `'Price Deviated'` or `'Consistent'`.

---

#### Task 4.3 — Frames

| Frame Type | Question |
|---|---|
| `ROWS` frame | 3-order moving average revenue per customer |
| `RANGE UNBOUNDED PRECEDING` | Company-wide cumulative revenue timeline |
| `RANGE INTERVAL 6 DAY` | 7-day rolling order count per order date |
| `FIRST_VALUE / LAST_VALUE` | Revenue of customer's first-ever and latest order line |

---

#### Task 4.4 — Lead and Lag Functions

**Q1:** Gap in days between consecutive orders per customer using `LAG(order_date, 1)` — identifies the customer with the largest gap.

**Q2:** Next order date and next order revenue using `LEAD(order_date, 1)` and `LEAD(line_revenue, 1)`.

**Q3:** Month-over-month revenue comparison using `LAG(total_revenue, 1)` on `vw_monthly_sales` — shows absolute and percentage change.

**Q4:** Detect repeat purchases of the same product by the same customer using `LAG()` partitioned by `(customer_id, product_id)`.

---

### 📊 Phase 5 — Grand Finale: The RetailPulse Dashboard Report

**Goal:** Five executive-level analytical queries forming a complete BI report.

---

#### Q1 — Customer Lifetime Value Tier Report
Per customer: total orders, delivered orders, total spend, `DENSE_RANK()` within their loyalty tier, and `PERCENT_RANK()` across all customers.

#### Q2 — Product Health Dashboard
Per product: units sold, revenue, return count, return rate, and a `health_label`:
- `'High Performer'` → revenue > ₹1,00,000 AND return rate < 5%
- `'Returned Frequently'` → return rate ≥ 10%
- `'Low Traction'` → units sold < 3
- `'Normal'` → everything else

#### Q3 — Channel and Coupon Effectiveness
Single query (no subqueries) using conditional aggregation:
- Per channel: total revenue, avg order value, unique customers
- Online only: % orders with/without coupon + avg revenue for each

#### Q4 — Customer Purchase Trajectory
For customers with ≥ 2 delivered orders — sequential purchase number, revenue change from previous order (`LAG`), 2-order moving average, and cumulative revenue.

#### Q5 — Monthly Registration Cohort Analysis
Groups customers by registration month — cohort size, total cohort revenue, best revenue month (using `RANK()`), and cohort label (`'High Value Cohort'` / `'Standard Cohort'`).

---

## 💡 Key Concepts Quick Reference

| Concept | When to Use |
|---|---|
| `HAVING` vs `WHERE` | `WHERE` filters rows before grouping; `HAVING` filters after aggregation |
| `UNION` vs `UNION ALL` | `UNION` for distinct results; `UNION ALL` for all rows including duplicates |
| `RANK` vs `DENSE_RANK` | `DENSE_RANK` when you don't want gaps after ties |
| Correlated Subquery vs CTE | CTE when you need to reuse the result; correlated subquery for row-by-row reference |
| `ROWS` vs `RANGE` frame | `ROWS` for exact row counts; `RANGE` for value-based (e.g., date intervals) |
| `LAG` vs `LEAD` | `LAG` looks back at previous rows; `LEAD` looks ahead at future rows |

---

## 🛠️ Tools Used

- **MySQL 8.0**
- **MySQL Workbench**

---

## 👤 Author

**Sharath Chandrika Kodumuri**  
Aspiring Data Analyst | Learning SQL through real-world projects  
🔗 [LinkedIn]([https://www.linkedin.com/in/sharathchandrika-kodumuri-65656324a/]) | 🐙 [GitHub][(https://github.com/Chandrika-04)]

---

> ⭐ If you found this helpful as a reference, feel free to star the repo!
