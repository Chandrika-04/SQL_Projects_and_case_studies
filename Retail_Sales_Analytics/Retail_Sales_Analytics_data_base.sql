-- ============================================================
--         SQL DATA CHALLENGE: RETAILPULSE ANALYTICS
--              "From Raw Records to Real Insights"
-- ============================================================
-- Author       : Sharath Chandrika Kodumrui
-- Environment  : MySQL 8.0 | MySQL Workbench
-- Description  : Complete SQL project for RetailPulse Inc. —
--                a mid-sized e-commerce and brick-and-mortar
--                retail chain operating across India.
--                Covers schema design, data manipulation,
--                business reporting, and window-based analytics.
-- ============================================================
 
-- ============================================================
-- DATABASE SETUP
-- ============================================================
create database if not exists Retail_Sales_Analytics;
use Retail_Sales_Analytics;
-- ============================================================
-- SCHEMA: TABLE DEFINITIONS AND SEED DATA
-- ============================================================
 
-- ------------------------------------------------------------
-- Table: customers
-- Stores customer profile and loyalty information
-- ------------------------------------------------------------
CREATE TABLE customers (
customer_id   INT PRIMARY KEY,
full_name     VARCHAR(100) NOT NULL,
email         VARCHAR(150) UNIQUE,
phone         VARCHAR(15),
city          VARCHAR(60),
state         VARCHAR(60),
registered_on DATE,
loyalty_tier  VARCHAR(20) DEFAULT 'Bronze' -- Bronze, Silver, Gold, Platinum
);
INSERT INTO customers VALUES

(1, 'Aryan Mehta', 'aryan@mail.com', '9876543210', 'Mumbai', 'Maharashtra', '2020-03-15', 'Gold'),

(2, 'Sneha Rao', 'sneha@mail.com', '9123456780', 'Hyderabad', 'Telangana', '2021-06-01', 'Silver'),

(3, 'Rahul Nair', 'rahul@mail.com', '9988776655', 'Kochi', 'Kerala', '2019-11-20', 'Platinum'),

(4, 'Priya Sharma', 'priya@mail.com', '9001122334', 'Delhi', 'Delhi', '2022-01-10', 'Bronze'),

(5, 'Karthik Iyer', 'karthik@mail.com', '9871234560', 'Chennai', 'Tamil Nadu', '2020-08-25', 'Gold'),

(6, 'Divya Pillai', 'divya@mail.com', '9345678901', 'Bangalore', 'Karnataka', '2021-03-18', 'Silver'),

(7, 'Aditya Singh', 'aditya@mail.com', '9456789012', 'Pune', 'Maharashtra', '2023-02-14', 'Bronze'),

(8, 'Meera Joshi', 'meera@mail.com', '9567890123', 'Ahmedabad', 'Gujarat', '2020-05-30', 'Platinum'),

(9, 'Rohan Das', 'rohan@mail.com', '9678901234', 'Kolkata', 'West Bengal', '2022-09-09', 'Silver'),

(10, 'Anjali Verma', 'anjali@mail.com', '9789012345', 'Jaipur', 'Rajasthan', '2019-12-01', 'Gold'),

(11, 'Nikhil Bose', NULL, '9890123456', 'Lucknow', 'Uttar Pradesh','2023-07-07', 'Bronze'),

(12, 'Tanya Sharma', 'tanya@mail.com', NULL, 'Chandigarh', 'Punjab', '2021-11-11', 'Silver');

-- ------------------------------------------------------------
-- Table: categories
-- Hierarchical product categories (supports self-referencing
-- parent-child relationships via parent_id)
-- ------------------------------------------------------------

CREATE TABLE categories (

category_id   INT PRIMARY KEY,

category_name VARCHAR(80) NOT NULL,

parent_id     INT,

FOREIGN KEY (parent_id) REFERENCES categories(category_id)

);
INSERT INTO categories VALUES

(1, 'Electronics', NULL),

(2, 'Clothing', NULL),

(3, 'Groceries', NULL),

(4, 'Home & Kitchen', NULL),

(5, 'Mobile Phones', 1),

(6, 'Laptops', 1),

(7, 'Mens Wear', 2),

(8, 'Womens Wear', 2),

(9, 'Dairy', 3),

(10, 'Snacks', 3);

-- ------------------------------------------------------------
-- Table: products
-- Product catalog with pricing, inventory, and supplier info
-- ------------------------------------------------------------

CREATE TABLE products (

product_id   INT PRIMARY KEY,

product_name VARCHAR(150) NOT NULL,

category_id  INT,

unit_price   DECIMAL(10,2) NOT NULL,

stock_qty    INT DEFAULT 0,

supplier     VARCHAR(100),

added_on     DATE,

FOREIGN KEY (category_id) REFERENCES categories(category_id)

);
INSERT INTO products VALUES

(101, 'Samsung Galaxy S23', 5, 72000.00, 50, 'Samsung India', '2023-01-10'),

(102, 'iPhone 14', 5, 95000.00, 30, 'Apple India', '2022-11-01'),

(103, 'Dell XPS 15', 6, 135000.00, 20, 'Dell India', '2022-08-15'),

(104, 'HP Pavilion 15', 6, 65000.00, 35, 'HP India', '2021-06-20'),

(105, 'Levis 511 Jeans', 7, 2999.00, 200, 'Levi Strauss', '2020-03-01'),

(106, 'Allen Solly Shirt', 7, 1499.00, 150, 'Madura Fashion', '2020-04-15'),

(107, 'Saree Silk Banarasi', 8, 8999.00, 80, 'Fabindia', '2021-09-10'),

(108, 'Amul Full Cream Milk 1L', 9, 65.00, 500, 'Amul', '2023-01-01'),

(109, 'Lays Classic Salted', 10, 20.00, 1000, 'PepsiCo India', '2022-12-01'),

(110, 'Prestige Pressure Cooker', 4, 3500.00, 90, 'TTK Prestige', '2021-07-20'),

(111, 'OnePlus 11', 5, 56000.00, 60, 'OnePlus India', '2023-02-05'),

(112, 'Noise SmartWatch', 1, 4999.00, 120, 'Noise', '2023-03-15');

-- ------------------------------------------------------------
-- Table: orders
-- Customer orders with channel and status tracking
-- ------------------------------------------------------------

CREATE TABLE orders (

order_id    INT PRIMARY KEY,

customer_id INT,

order_date  DATE NOT NULL,

status VARCHAR(30) DEFAULT 'Pending', -- Pending, Shipped, Delivered, Cancelled

channel     VARCHAR(30), -- Online, In-Store

coupon_code VARCHAR(20),

FOREIGN KEY (customer_id) REFERENCES customers(customer_id)

);

INSERT INTO orders VALUES

(1001, 1, '2023-01-15', 'Delivered', 'Online', 'SAVE10'),

(1002, 2, '2023-01-20', 'Delivered', 'In-Store', NULL),

(1003, 3, '2023-02-05', 'Delivered', 'Online', 'FLAT200'),

(1004, 4, '2023-02-18', 'Cancelled', 'Online', NULL),

(1005, 5, '2023-03-10', 'Delivered', 'In-Store', NULL),

(1006, 1, '2023-03-22', 'Delivered', 'Online', 'SAVE10'),

(1007, 6, '2023-04-01', 'Shipped', 'Online', NULL),

(1008, 3, '2023-04-15', 'Delivered', 'Online', 'FLAT200'),

(1009, 7, '2023-05-05', 'Pending', 'Online', NULL),

(1010, 8, '2023-05-20', 'Delivered', 'In-Store', NULL),

(1011, 2, '2023-06-10', 'Delivered', 'Online', NULL),

(1012, 9, '2023-06-25', 'Delivered', 'Online', 'SAVE10'),

(1013, 10, '2023-07-04', 'Cancelled', 'In-Store', NULL),

(1014, 5, '2023-07-19', 'Delivered', 'Online', NULL),

(1015, 11, '2023-08-08', 'Delivered', 'Online', NULL),

(1016, 1, '2023-08-21', 'Delivered', 'In-Store', NULL),

(1017, 12, '2023-09-03', 'Shipped', 'Online', NULL),

(1018, 3, '2023-09-17', 'Delivered', 'Online', 'FLAT200'),

(1019, 6, '2023-10-02', 'Delivered', 'Online', NULL),

(1020, 8, '2023-10-30', 'Delivered', 'In-Store', NULL);

-- ------------------------------------------------------------
-- Table: order_items
-- Line items for each order — tracks product, qty, and pricing
-- ------------------------------------------------------------


CREATE TABLE order_items (

item_id      INT PRIMARY KEY,

order_id     INT,

product_id   INT,

quantity     INT NOT NULL,

unit_price   DECIMAL(10,2) NOT NULL, -- price at the time of the order

discount_pct DECIMAL(5,2) DEFAULT 0.00,

FOREIGN KEY (order_id) REFERENCES orders(order_id),

FOREIGN KEY (product_id) REFERENCES products(product_id)

);
INSERT INTO order_items VALUES

(1, 1001, 101, 1, 72000.00, 5.00),

(2, 1001, 109, 3, 20.00, 0.00),

(3, 1002, 105, 2, 2999.00, 0.00),

(4, 1002, 106, 1, 1499.00, 10.00),

(5, 1003, 102, 1, 95000.00, 3.00),

(6, 1003, 110, 1, 3500.00, 0.00),

(7, 1004, 103, 1, 135000.00, 0.00),

(8, 1005, 104, 1, 65000.00, 5.00),

(9, 1006, 111, 1, 56000.00, 2.00),

(10, 1006, 112, 1, 4999.00, 0.00),

(11, 1007, 107, 2, 8999.00, 0.00),

(12, 1008, 101, 1, 72000.00, 5.00),

(13, 1008, 108, 5, 65.00, 0.00),

(14, 1009, 104, 1, 65000.00, 0.00),

(15, 1010, 110, 2, 3500.00, 5.00),

(16, 1011, 109, 10, 20.00, 0.00),

(17, 1011, 108, 4, 65.00, 0.00),

(18, 1012, 112, 1, 4999.00, 8.00),

(19, 1013, 107, 1, 8999.00, 0.00),

(20, 1014, 102, 1, 95000.00, 2.00),

(21, 1015, 111, 1, 56000.00, 0.00),

(22, 1016, 105, 3, 2999.00, 0.00),

(23, 1017, 103, 1, 135000.00, 4.00),

(24, 1018, 101, 2, 72000.00, 5.00),

(25, 1019, 106, 2, 1499.00, 0.00),

(26, 1020, 110, 1, 3500.00, 0.00);

-- ------------------------------------------------------------
-- Table: returns
-- Tracks product returns, reasons, and refund amounts
-- ------------------------------------------------------------

CREATE TABLE returns (

return_id     INT PRIMARY KEY,

order_id      INT,

product_id    INT,

return_date   DATE NOT NULL,

reason        VARCHAR(200),

refund_amount DECIMAL(10,2),

FOREIGN KEY (order_id) REFERENCES orders(order_id),

FOREIGN KEY (product_id) REFERENCES products(product_id)

);
INSERT INTO returns VALUES

(1, 1004, 103, '2023-02-25', 'Product defective on arrival', 135000.00),

(2, 1005, 104, '2023-03-20', 'Changed mind', 65000.00),

(3, 1013, 107, '2023-07-10', 'Size mismatch', 8999.00);
