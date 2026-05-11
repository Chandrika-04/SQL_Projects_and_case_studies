CREATE DATABASE IF NOT EXISTS Ecommerce_Bussiness;
USE Ecommerce_Bussiness;
CREATE TABLE Departments(
dept_id INT PRIMARY KEY AUTO_INCREMENT,
dept_name VARCHAR(100) NOT NULL,
dept_loaction VARCHAR(100) NOT NULL,
budget Decimal(15,2) Default 0.00
);
CREATE TABLE Employees(
emp_id INT PRIMARY KEY AUTO_INCREMENT,
fullname VARCHAR(200) NOT NULL,
email VARCHAR(100) UNIQUE NOT NULL,
hiredate DATE NOT NULL,
salary Decimal(10,2) NOT NULL,
dept_id INT,
manager_id INT,
FOREIGN KEY (dept_id) REFERENCES Departments(dept_id),
FOREIGN KEY(manager_id) REFERENCES Employees(emp_id)
);
use Ecommerce_Bussiness;
CREATE TABLE Customers(
customer_id INT PRIMARY KEY AUTO_INCREMENT,
full_name VARCHAR(200) NOT NULL,
email VARCHAR(200) UNIQUE NOT NULL,
city VARCHAR(200),
Country VARCHAR(100) DEFAULT 'India',
joined_date  DATE NOT NULL,
tier ENUM('Bronze','Silver','Gold','Platinum') DEFAULT 'Bronze'     
);
CREATE TABLE products (
product_id INT PRIMARY KEY AUTO_INCREMENT,
product_name VARCHAR(200) NOT NULL,
category   VARCHAR(100),
unit_price  DECIMAL(10,2) NOT NULL,
stock_qty   INT DEFAULT 0,
supplier  VARCHAR(150) 
);
CREATE TABLE orders (
order_id INT PRIMARY KEY AUTO_INCREMENT,
customer_id INT NOT NULL,
emp_id INT,
order_date DATETIME NOT NULL DEFAULT current_timestamp,
Status ENUM('Pending','Processing','Shipped','Delivered','Cancelled') DEFAULT 'Pending',
shipping_city VARCHAR(100),
FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
FOREIGN KEY (emp_id) REFERENCES employees(emp_id)
);
CREATE TABLE order_items (
item_id  INT PRIMARY KEY AUTO_INCREMENT,
order_id  INT NOT NULL,
product_id  INT NOT NULL,
quantity    INT NOT NULL CHECK (quantity > 0),
unit_price  DECIMAL(10,2) NOT NULL,
discount    DECIMAL(5,2) DEFAULT 0.00,
FOREIGN KEY (order_id) REFERENCES orders(order_id),
FOREIGN KEY (product_id) REFERENCES products(product_id)
);
CREATE TABLE payments (
payment_id  INT PRIMARY KEY AUTO_INCREMENT,
order_id    INT  UNIQUE NOT NULL,
paid_amount  DECIMAL(10,2) NOT NULL,
payment_date  DATETIME NOT NULL,
method   ENUM('Credit Card','Debit Card','UPI','Net Banking','Wallet','COD'),     
status ENUM('Pending','Completed','Failed','Refunded') DEFAULT 'Pending',
FOREIGN KEY (order_id) REFERENCES orders(order_id)
);
-- Add a phone column to customers
ALTER TABLE customers ADD COLUMN phone VARCHAR(20) AFTER email;
-- Modify tier column to expand enum
ALTER TABLE customers MODIFY COLUMN tier ENUM('Bronze','Silver','Gold','Platinum','Diamond')
DEFAULT 'Bronze';
-- Add index on order_date for performance
ALTER TABLE orders ADD INDEX idx_order_date (order_date);
-- Add a composite index
ALTER TABLE order_items ADD INDEX idx_order_product (order_id, product_id);
-- Drop a column
ALTER TABLE customers DROP COLUMN phone;
-- Renaming the dept_location from employee table
-- DEPARTMENTS (6 rows)-- ─────────────────────────────────────
INSERT INTO departments (dept_name, dept_location, budget) VALUES
('Sales','Mumbai',1500000.00),
('Engineering','Bangalore', 3000000.00),
('Marketing','Delhi',1200000.00),
('Customer Care', 'Hyderabad', 800000.00),
('Finance','Mumbai',2000000.00),
('Logistics','Chennai',950000.00);
SELECT * FROM DEPARTMENTS;
-- ─────────────────────────────────────-- EMPLOYEES (20 rows)-- ─────────────────────────────────────
INSERT INTO employees (fullname, email, hiredate, salary, dept_id, manager_id) VALUES
('Arjun Mehta', 'arjun.mehta@shop.com', '2018-03-15', 95000.00, 1, NULL),
('Sneha Kapoor', 'sneha.kapoor@shop.com', '2019-07-01', 88000.00, 1, 1),
('Rohan Verma', 'rohan.verma@shop.com', '2020-01-20', 72000.00, 1, 1),
('Priya Nair', 'priya.nair@shop.com', '2017-11-05', 110000.00, 2, NULL),
('Karan Singh', 'karan.singh@shop.com', '2021-06-10', 85000.00, 2, 4),
('Divya Iyer', 'divya.iyer@shop.com', '2022-02-28', 78000.00, 2, 4),
('Amit Sharma', 'amit.sharma@shop.com', '2016-08-19', 105000.00, 3, NULL),
('Neha Gupta', 'neha.gupta@shop.com', '2020-09-14', 68000.00, 3, 7),
('Vikram Joshi', 'vikram.joshi@shop.com', '2023-01-02', 62000.00, 3, 7),
('Anjali Rao', 'anjali.rao@shop.com', '2019-04-22', 74000.00, 4, NULL),
('Suresh Patil', 'suresh.patil@shop.com', '2021-11-30', 58000.00, 4, 10),
('Meena Reddy', 'meena.reddy@shop.com', '2022-08-15', 61000.00, 4, 10),
('Rahul Desai', 'rahul.desai@shop.com', '2018-05-07', 120000.00, 5, NULL),
('Pooja Bhatt', 'pooja.bhatt@shop.com', '2020-12-01', 82000.00, 5, 13),
('Sanjay Kumar', 'sanjay.kumar@shop.com', '2017-03-25', 98000.00, 6, NULL),
('Tanya Mishra', 'tanya.mishra@shop.com', '2021-07-19', 67000.00, 6, 15),
('Harish Pillai', 'harish.pillai@shop.com', '2022-10-10', 59000.00, 6, 15),
('Kavya Menon', 'kavya.menon@shop.com', '2023-04-03', 55000.00, 2, 4),
('Ravi Tiwari', 'ravi.tiwari@shop.com', '2019-09-17', 77000.00, 1, 1),
('Deepa Shetty', 'deepa.shetty@shop.com', '2020-06-25', 71000.00, 3, 7);

-- ─────────────────────────────────────-- CUSTOMERS (25 rows)-- ─────────────────────────────────────
INSERT INTO customers (full_name, email, city, country, joined_date, tier) VALUES 
('Aditya Patel', 'aditya.p@gmail.com', 'Ahmedabad', 'India', '2021-01-10', 'Gold'),
('Bhavna Shah', 'bhavna.s@gmail.com', 'Surat', 'India', '2020-05-22', 'Silver'),
('Chirag Mehta', 'chirag.m@yahoo.com', 'Mumbai', 'India', '2019-11-30', 'Platinum'),
('Deepika Roy', 'deepika.r@gmail.com', 'Kolkata', 'India', '2022-03-15', 'Bronze'),
('Esha Nanda', 'esha.n@hotmail.com', 'Delhi', 'India', '2021-07-08', 'Silver'),
('Farhan Sheikh', 'farhan.s@gmail.com', 'Pune', 'India', '2020-09-19', 'Gold'),
('Girish Iyer', 'girish.i@gmail.com', 'Chennai', 'India', '2023-01-25', 'Bronze'),
('Hina Siddiqui', 'hina.s@gmail.com', 'Hyderabad', 'India', '2019-06-14', 'Platinum'),
('Ishaan Verma', 'ishaan.v@gmail.com', 'Jaipur', 'India', '2022-08-30', 'Bronze'),
('Jaya Krishnan', 'jaya.k@gmail.com', 'Bangalore', 'India', '2020-12-05', 'Gold'),
('Kiran Reddy', 'kiran.r@gmail.com', 'Hyderabad', 'India', '2021-04-17', 'Silver'),
('Lavanya Menon', 'lavanya.m@gmail.com', 'Kochi', 'India', '2023-06-01', 'Bronze'),
('Mohit Kapoor', 'mohit.k@gmail.com', 'Delhi', 'India', '2018-10-22', 'Platinum'),
('Nisha Arora', 'nisha.a@gmail.com', 'Chandigarh', 'India', '2022-02-11', 'Silver'),
('Om Prakash', 'om.p@gmail.com', 'Lucknow', 'India', '2021-11-03', 'Bronze'),
('Pallavi Joshi', 'pallavi.j@gmail.com', 'Nagpur', 'India', '2020-07-27', 'Gold'),
('Qureshi Aslam', 'qureshi.a@gmail.com', 'Bhopal', 'India', '2019-03-09', 'Silver'),
('Radha Pillai', 'radha.p@gmail.com', 'Trivandrum', 'India', '2023-09-14', 'Bronze'),
('Sameer Bose', 'sameer.b@gmail.com', 'Kolkata', 'India', '2021-05-20', 'Gold'),
('Tara Nair', 'tara.n@gmail.com', 'Bangalore', 'India', '2020-01-16', 'Platinum'),
('Uday Chandra', 'uday.c@gmail.com', 'Visakhapatnam', 'India', '2022-10-08', 'Bronze'),
('Vani Subramaniam', 'vani.s@gmail.com', 'Chennai', 'India', '2021-08-23', 'Silver'),
('Wasim Khan', 'wasim.k@gmail.com', 'Mumbai', 'India', '2019-12-31', 'Gold'),
('Xena DSouza', 'xena.ds@gmail.com', 'Goa', 'India', '2023-03-07', 'Bronze'),
('Yogesh Shinde', 'yogesh.sh@gmail.com', 'Nashik', 'India', '2020-04-14', 'Silver');
-- ─────────────────────────────────────-- PRODUCTS (20 rows)-- ────────────────────────────────────
INSERT INTO products (product_name, category, unit_price, stock_qty, supplier) VALUES
('iPhone 15 Pro', 'Electronics', 129999.00, 150, 'Apple India'),
('Samsung Galaxy S24', 'Electronics', 89999.00, 200, 'Samsung India'),
('Sony WH-1000XM5', 'Electronics', 29999.00, 300, 'Sony India'),
('Dell XPS 15 Laptop', 'Electronics', 189999.00, 80, 'Dell India'),
('Kindle Paperwhite', 'Electronics', 13999.00, 400, 'Amazon India'),
('Nike Air Max 270', 'Footwear', 8999.00, 500, 'Nike India'),
('Adidas Ultraboost 23', 'Footwear', 12999.00, 350, 'Adidas India'),
('Levis 511 Slim Jeans', 'Apparel', 3999.00, 600, 'Levi Strauss India'),
('Allen Solly Formal Shirt', 'Apparel', 2499.00, 700, 'Madura Fashion'),
('Prestige Rice Cooker', 'Appliances', 3499.00, 250, 'TTK Prestige'),
('Philips Air Fryer', 'Appliances', 8999.00, 180, 'Philips India'),
('Godrej Refrigerator', 'Appliances', 42999.00, 60, 'Godrej Appliances'),
('Himalaya Face Wash', 'Beauty', 299.00, 1200, 'Himalaya Herbals'),
('Lakme Lipstick', 'Beauty', 499.00, 900, 'Hindustan Unilever'),
('Yoga Mat Premium', 'Sports', 1499.00, 450, 'Decathlon India'),
('Cricket Bat SS Ton', 'Sports', 4999.00, 200, 'SS Sports'),
('Harry Potter Box Set', 'Books', 1999.00, 350, 'Bloomsbury India'),
('Atomic Habits', 'Books', 499.00, 800, 'Penguin India'),
('Wooden Study Table', 'Furniture', 12999.00, 90, 'Pepperfry'),
('Ergonomic Office Chair', 'Furniture', 18999.00, 70, 'Urban Ladder');
-- ─────────────────────────────────────-- ORDERS (30 rows)-- ─────────────────────────────────────
INSERT INTO orders (customer_id, emp_id, order_date, status, shipping_city) VALUES
(3, 2, '2024-01-05 10:23:00', 'Delivered', 'Mumbai'),
(8, 2, '2024-01-12 14:05:00', 'Delivered', 'Hyderabad'),
(13, 3, '2024-01-18 09:45:00', 'Delivered', 'Delhi'),
(1, 19, '2024-02-02 11:30:00', 'Delivered', 'Ahmedabad'),
(20, 2, '2024-02-14 16:00:00', 'Delivered', 'Bangalore'),
(6, 19, '2024-02-20 13:20:00', 'Delivered', 'Pune'),
(10, 3, '2024-03-03 10:10:00', 'Delivered', 'Bangalore'),
(16, 2, '2024-03-15 15:45:00', 'Shipped', 'Nagpur'),
(23, 19, '2024-03-22 12:00:00', 'Delivered', 'Pune'),
(5, 3, '2024-04-01 09:00:00', 'Delivered', 'Delhi'),
(11, 2, '2024-04-10 17:30:00', 'Cancelled', 'Hyderabad'),
(2, 19, '2024-04-18 14:15:00', 'Delivered', 'Surat'),
(19, 3, '2024-04-25 11:00:00', 'Delivered', 'Kolkata'),
(7, 2, '2024-05-05 10:45:00', 'Processing', 'Chennai'),
(25, 19, '2024-05-12 13:00:00', 'Delivered', 'Nashik'),
(4, 3, '2024-05-20 09:30:00', 'Pending', 'Kolkata'),
(12, 2, '2024-06-01 16:20:00', 'Delivered', 'Kochi'),
(17, 19, '2024-06-08 14:00:00', 'Delivered', 'Bhopal'),
(22, 3, '2024-06-15 10:00:00', 'Shipped', 'Chennai'),
(9, 2, '2024-07-02 11:45:00', 'Delivered', 'Jaipur'),
(14, 19, '2024-07-10 15:00:00', 'Delivered', 'Chandigarh'),
(24, 3, '2024-07-18 09:00:00', 'Cancelled', 'Goa'),
(3, 2, '2024-08-01 13:30:00', 'Delivered', 'Mumbai'),
(8, 19, '2024-08-10 10:00:00', 'Delivered', 'Hyderabad'),
(20, 3, '2024-08-20 14:45:00', 'Processing', 'Bangalore'),
(1, 2, '2024-09-05 09:15:00', 'Delivered', 'Ahmedabad'),
(13, 19, '2024-09-14 16:30:00', 'Delivered', 'Delhi'),
(6, 3, '2024-09-22 11:00:00', 'Delivered', 'Pune'),
(15, 2, '2024-10-03 10:30:00', 'Delivered', 'Lucknow'),
(21, 19, '2024-10-15 15:00:00', 'Shipped', 'Visakhapatnam');
-- ─────────────────────────────────────-- ORDER_ITEMS (40 rows)-- ─────────────────────────────────────
INSERT INTO order_items (order_id, product_id, quantity, unit_price, discount) VALUES
(1, 1, 1, 129999.00, 5.00),
(1, 3, 1, 29999.00, 0.00),
(2, 4, 1, 189999.00, 8.00),
(3, 2, 1, 89999.00, 3.00),
(3, 5, 2, 13999.00, 0.00),
(4, 6, 2, 8999.00, 0.00),
(4, 8, 1, 3999.00, 5.00),
(5, 1, 1, 129999.00, 10.00),
(6, 11, 1, 8999.00, 0.00),
(6, 10, 2, 3499.00, 0.00),
(7, 12, 1, 42999.00, 5.00),
(8, 7, 2, 12999.00, 0.00),
(9, 9, 3, 2499.00, 10.00),
(10, 13, 5,299.00, 0.00),
(10, 14, 3,499.00, 0.00),
(11, 2, 1, 89999.00, 0.00),
(12, 15, 2, 1499.00, 0.00),
(12, 16, 1, 4999.00, 0.00),
(13, 4, 1, 189999.00, 12.00),
(14, 17, 1, 1999.00, 0.00),
(14, 18, 2,499.00, 0.00),
(15, 3, 1, 29999.00, 5.00),
(17, 19, 1, 12999.00, 0.00),
(17, 20, 1, 18999.00, 0.00),
(18, 6, 1, 8999.00, 5.00),
(18, 7, 1, 12999.00, 5.00),
(19, 1, 1, 129999.00, 7.00),
(20, 5, 1, 13999.00, 0.00),
(20, 18, 3,499.00, 0.00),
(21, 8, 2, 3999.00, 0.00),
(21, 9, 2, 2499.00, 0.00),
(22, 11, 1, 8999.00, 15.00),
(23, 2, 1, 89999.00, 5.00),
(23, 3, 1, 29999.00, 0.00),
(24, 12, 1, 42999.00, 0.00),
(26, 1, 2, 129999.00, 8.00),
(27, 4, 1, 189999.00, 10.00),
(28, 6, 3, 8999.00, 0.00),
(29, 16, 2, 4999.00, 5.00),
(30, 20, 1, 18999.00, 0.00);
-- ─────────────────────────────────────-- PAYMENTS (27 rows)-- ────────────────────────────────────
INSERT INTO payments (order_id, paid_amount, payment_date, method, status) VALUES
(1, 151398.05, '2024-01-05 10:30:00', 'Credit Card', 'Completed'),
(2, 174799.08, '2024-01-12 14:10:00', 'Net Banking', 'Completed'),
(3, 115597.02, '2024-01-18 09:50:00', 'UPI','Completed'),
(4, 21797.05, '2024-02-02 11:35:00', 'Debit Card', 'Completed'),
(5, 116999.10, '2024-02-14 16:05:00', 'Credit Card', 'Completed'),
(6, 15997.00, '2024-02-20 13:25:00', 'UPI','Completed'),
(7, 40849.05, '2024-03-03 10:15:00', 'Wallet','Completed'),
(8, 25998.00, '2024-03-15 15:50:00', 'COD','Completed'),
(9,6747.30, '2024-03-22 12:05:00', 'UPI','Completed'),
(10, 2992.00, '2024-04-01 09:05:00', 'UPI','Completed'),
(11,0.00, '2024-04-10 17:35:00', 'Credit Card', 'Refunded'),
(12, 6498.00, '2024-04-18 14:20:00', 'Debit Card', 'Completed'),
(13, 167199.16, '2024-04-25 11:05:00', 'Net Banking', 'Completed'),
(15, 28499.05, '2024-05-12 13:05:00', 'Credit Card', 'Completed'),
(17, 31998.00, '2024-06-01 16:25:00', 'UPI','Completed'),
(18, 19799.00, '2024-06-08 14:05:00', 'Wallet','Completed'),
(19, 20799.00, '2024-06-15 10:05:00', 'Credit Card', 'Completed'),
(20, 15494.00, '2024-07-02 11:50:00', 'COD','Completed'),
(21, 12996.00, '2024-07-10 15:05:00', 'UPI','Completed'),
(22,0.00, '2024-07-18 09:05:00', 'Credit Card', 'Refunded'),
(23, 24498.60, '2024-08-01 13:35:00', 'Credit Card', 'Completed'),
(24, 42999.00, '2024-08-10 10:05:00', 'Net Banking', 'Completed'),
(26, 239198.16, '2024-09-05 09:20:00', 'Credit Card', 'Completed'),
(27, 170999.10, '2024-09-14 16:35:00', 'UPI','Completed'),
(28, 26997.00, '2024-09-22 11:05:00', 'Debit Card', 'Completed'),
(29, 9498.10, '2024-10-03 10:35:00', 'COD','Completed'),
(30, 18999.00, '2024-10-15 15:05:00', 'Wallet','Completed');







