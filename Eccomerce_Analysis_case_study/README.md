# 🛒 SQL E-Commerce Case Study

A comprehensive SQL project built around a realistic e-commerce business scenario, covering everything from basic SELECT queries to advanced window functions, CTEs, and pivot-style reports — all written in **MySQL Workbench**.

---

## 📁 Project Structure

```
sql-ecommerce-casestudy/
├── schema/
│   └── ddl.sql               # CREATE TABLE statements + ALTER TABLE examples
├── data/
│   └── dml.sql               # INSERT statements (sample data)
├── queries/
│   ├── beginner.sql          # Q1  – Q5
│   ├── intermediate.sql      # Q6  – Q15
│   ├── advanced.sql          # Q16 – Q28
│   └── advanced_ext.sql      # Q29 – Q43
└── README.md
```

---

## 🗄️ Database Schema

The project uses **7 related tables** modelling a real-world e-commerce operation:

| Table | Description |
|---|---|
| `departments` | Company departments with budget and location |
| `employees` | Staff records with salary, hire date, and manager (self-join) |
| `customers` | Registered customers with city, tier, and join date |
| `products` | Product catalogue with category, price, and stock |
| `orders` | Customer orders handled by a sales rep employee |
| `order_items` | Line items per order with quantity, price, and discount |
| `payments` | One payment per order with method and status |

### ER Relationships

```
departments  1──M  employees   (dept_id)
employees    1──M  employees   (manager_id → self-join)
customers    1──M  orders      (customer_id)
employees    1──M  orders      (emp_id — sales rep)
orders       1──M  order_items (order_id)
products     1──M  order_items (product_id)
orders       1──1  payments    (order_id)
```

---

## 📊 Sample Data

| Table | Rows |
|---|---|
| departments | 6 |
| employees | 20 |
| customers | 25 |
| products | 20 |
| orders | 30 |
| order_items | 40 |
| payments | 27 |

---

## 📝 Questions Covered (43 Total)

### 🟢 Beginner (Q1 – Q5)

| # | Title | Key Concept |
|---|---|---|
| Q1 | Customers from a Specific City | `WHERE`, `ORDER BY` |
| Q2 | Products Below a Price Threshold | Filtering with comparison operators |
| Q3 | Count of Employees per Department | `GROUP BY`, `HAVING`, `COUNT` |
| Q4 | Total Revenue per Order | `SUM`, arithmetic in SELECT |
| Q5 | Orders Placed in Q1 2024 | Date range filtering with `BETWEEN` |

### 🟡 Intermediate (Q6 – Q15)

| # | Title | Key Concept |
|---|---|---|
| Q6 | Top 5 Customers by Total Spend | `JOIN`, `SUM`, `LIMIT` |
| Q7 | Monthly Revenue Trend in 2024 | `DATE_FORMAT`, `GROUP BY` month |
| Q8 | Products Never Ordered | `LEFT JOIN` + `IS NULL` |
| Q9 | Employees and Their Managers | Self-join with `LEFT JOIN` |
| Q10 | Average Order Value per Customer Tier | Multi-table join, `AVG` |
| Q11 | Customers Who Ordered More Than Once | `HAVING COUNT > 1` |
| Q12 | Masked Email Report | `SUBSTRING_INDEX`, `CONCAT` |
| Q13 | Days Since Last Order per Customer | `DATEDIFF`, `MAX` |
| Q14 | Revenue by Category (with Discounts) | Discount formula in aggregation |
| Q15 | Employees Above Department Avg Salary | Correlated subquery / subquery in `WHERE` |

### 🔴 Advanced (Q16 – Q28)

| # | Title | Key Concept |
|---|---|---|
| Q16 | Rank Customers by Spend Within Tier | `RANK()` with `PARTITION BY` |
| Q17 | Running Total of Revenue Over Time | `SUM() OVER` with frame clause |
| Q18 | Sales Rep Performance Dashboard | Named window (`WINDOW` clause) |
| Q19 | Month-over-Month Revenue Growth | CTE + `LAG()` |
| Q20 | View: Active Customer Summary | `CREATE VIEW`, querying a view |
| Q21 | Full Management Chain (Two-Level Self Join) | Multi-level self-join |
| Q22 | Gmail Customers & Two-Word Names | `REGEXP` |
| Q23 | Top 3 Products per Category by Revenue | `DENSE_RANK()` with `PARTITION BY` |
| Q24 | Orders with No or Failed Payment | `LEFT JOIN` on payments |
| Q25 | Pivot-Style Orders per Status per Month | Conditional aggregation (`CASE WHEN`) |
| Q26 | Duplicate Customer Name Detection | `GROUP BY` + `HAVING COUNT > 1`, `GROUP_CONCAT` |
| Q27 | Products Ordered by Both Customer 3 & 8 | INTERSECT alternative using `IN` subqueries |
| Q28 | Most Popular Payment Method per Tier | `RANK()` over payment method counts |

### 🟣 Advanced Extended (Q29 – Q43)

| # | Title | Key Concept |
|---|---|---|
| Q29 | All Orders with Customer Names | Multi-table JOIN |
| Q30 | Electronics Products Sorted by Price | Category filter + `ORDER BY` |
| Q31 | Order Count per Status | `GROUP BY` status |
| Q32 | Employees with Mid-Range Salary | `BETWEEN` on salary |
| Q33 | Most Recently Joined Customer per Tier | `MAX` + `GROUP BY` tier |
| Q34 | Payment Method Usage Summary | `COUNT`, `SUM` on payments |
| Q35 | Customers Who Never Placed an Order | `LEFT JOIN` + `IS NULL` |
| Q36 | Employee Tenure in Years and Months | `TIMESTAMPDIFF` |
| Q37 | Orders with More Than One Product | `HAVING COUNT > 1` on order_items |
| Q38 | Category with Highest Average Price | `AVG`, `GROUP BY` category |
| Q39 | Full Name & Email Domain Extraction | `UPPER()`, `SUBSTRING_INDEX()` |
| Q40 | Orders Shipped to a Different City | Comparing customer city vs shipping city |
| Q41 | Top Selling Product per Category | `RANK()`/subquery over quantity sums |
| Q42 | Employees Sharing the Same Manager | Self-join + `GROUP_CONCAT` |
| Q43 | Revenue Contribution % per Product | Subquery for total, percentage calculation |

---

## 🛠️ How to Run

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd sql-ecommerce-casestudy
   ```

2. **Open MySQL Workbench** and connect to your local MySQL server.

3. **Create the database**
   ```sql
   CREATE DATABASE ecommerce_db;
   USE ecommerce_db;
   ```

4. **Run the scripts in order**
   ```
   schema/ddl.sql   →  creates all tables
   data/dml.sql     →  inserts sample data
   queries/*.sql    →  run any question file
   ```

---

## 🧠 Concepts Demonstrated

| Category | Topics |
|---|---|
| **Joins** | INNER JOIN, LEFT JOIN, Self Join, Multi-level Join |
| **Aggregation** | COUNT, SUM, AVG, MAX, MIN with GROUP BY / HAVING |
| **Subqueries** | Correlated subqueries, subqueries in WHERE / FROM |
| **Window Functions** | RANK(), DENSE_RANK(), ROW_NUMBER(), SUM() OVER, LAG(), named WINDOW |
| **CTEs** | WITH clause, chained CTEs |
| **String Functions** | UPPER(), SUBSTRING_INDEX(), CONCAT(), REGEXP |
| **Date Functions** | DATE_FORMAT(), DATEDIFF(), TIMESTAMPDIFF() |
| **Conditional Logic** | CASE WHEN (pivot-style reports) |
| **DDL / DML** | CREATE, ALTER TABLE, INSERT, CREATE VIEW |
| **Performance** | INDEX creation, composite indexes |

---

## 💡 Key Highlights

- **Discount-aware revenue** — all revenue calculations correctly apply `quantity * unit_price * (1 - discount/100)`
- **Self-referencing employees** — manager hierarchy solved with self-joins at both one and two levels
- **INTERSECT alternative** — MySQL doesn't support INTERSECT natively; Q27 demonstrates the equivalent using subqueries
- **Pivot without PIVOT** — Q25 uses conditional `SUM(CASE WHEN ...)` to create a cross-tab report
- **View + filter pattern** — Q20 creates a reusable view and queries it with additional filters on top

---

## 🔧 Environment

- **Database**: MySQL 8.x
- **Tool**: MySQL Workbench
- **SQL Dialect**: MySQL (ANSI-compatible where possible)

---

## 👤 Author

**Sharathchandrika Kodumuri**
[GitHub](https://github.com/Chandrika-04) · [LinkedIn](https://linkedin.com/in/sharathchandrika-kodumuri-65656324a)

---

## 📄 License

This project is open for learning and portfolio purposes. Feel free to fork, adapt, and reference it.
