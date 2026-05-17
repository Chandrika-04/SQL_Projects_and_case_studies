-- ####################################################################
-- ###################### SALES SQL CASE STUDY #########################
-- ####################################################################
-- =====================================================
-- DATABASE CREATION
-- =====================================================

CREATE DATABASE sales_case_study;
USE sales_case_study;

-- =====================================================
-- TABLE CREATION
-- =====================================================

CREATE TABLE ProductTable (
    ProductID INT PRIMARY KEY,
    ProductType VARCHAR(20),
    Product VARCHAR(50),
    Type VARCHAR(20)
);
CREATE TABLE LocationTable (
    Area_Code INT,
    State VARCHAR(50),
    Market VARCHAR(50),
    Market_Size VARCHAR(30)
);
CREATE TABLE FactTable (
    Date DATE,
    ProductID INT,
    Profit DECIMAL(10,2),
    Sales DECIMAL(10,2),
    Margin DECIMAL(10,2),
    COGS DECIMAL(10,2),
    Total_Expenses DECIMAL(10,2),
    Marketing DECIMAL(10,2),
    Inventory INT,
    Budget_Profit DECIMAL(10,2),
    Budget_COGS DECIMAL(10,2),
    Budget_Margin DECIMAL(10,2),
    Budget_Sales DECIMAL(10,2),
    Area_Code INT,

    FOREIGN KEY (ProductID) REFERENCES ProductTable(ProductID)
);

-- =====================================================
-- INSERTING DATA
-- =====================================================
INSERT INTO ProductTable VALUES
(1, 'Coffee', 'Colombian Coffee', 'Regular'),
(2, 'Tea', 'Green Tea', 'Regular'),
(3, 'Coffee', 'Espresso', 'Regular'),
(4, 'Tea', 'Black Tea', 'Decaf'),
(5, 'Coffee', 'Cappuccino', 'Regular'),
(6, 'Tea', 'Herbal Tea', 'Regular'),
(7, 'Coffee', 'Latte', 'Decaf'),
(8, 'Tea', 'Lemon Tea', 'Regular'),
(9, 'Coffee', 'Mocha', 'Regular'),
(10, 'Tea', 'Masala Tea', 'Regular'),
(11, 'Coffee', 'Americano', 'Regular'),
(12, 'Tea', 'Ice Tea', 'Decaf'),
(13, 'Coffee', 'Cold Brew', 'Regular');

INSERT INTO LocationTable VALUES
(719, 'Colorado', 'West', 'Large'),
(720, 'California', 'West', 'Large'),
(305, 'Florida', 'East', 'Medium'),
(212, 'New York', 'East', 'Large'),
(512, 'Texas', 'South', 'Large'),
(404, 'Georgia', 'South', 'Medium'),
(602, 'Arizona', 'West', 'Small'),
(618, 'Illinois', 'Central', 'Medium'),
(901, 'Tennessee', 'South', 'Small'),
(808, 'Hawaii', 'West', 'Small');

INSERT INTO FactTable VALUES
('2010-01-01',1,120,500,150,350,45,20,100,100,300,120,450,719),
('2010-01-01',2,80,400,100,300,55,15,120,70,250,110,420,720),
('2010-01-02',3,150,650,200,450,65,25,130,140,400,180,600,305),
('2010-01-02',4,60,300,90,210,35,10,80,50,180,90,280,212),
('2010-01-03',5,200,800,250,550,120,40,160,180,500,200,750,512),
('2010-01-03',6,75,350,100,250,50,12,90,65,200,100,320,404),
('2010-01-04',7,95,450,130,320,85,18,110,90,280,125,410,602),
('2010-01-04',8,50,280,70,210,150,8,70,45,170,80,260,618),
('2010-01-05',9,175,720,220,500,95,30,140,160,450,190,680,901),
('2010-01-05',10,65,310,85,225,45,11,85,55,190,85,300,808),
('2010-01-06',11,210,900,300,600,180,50,180,200,550,250,850,719),
('2010-01-06',12,40,250,60,190,110,7,60,35,160,70,240,720),
('2010-01-07',13,160,700,210,490,75,28,150,150,430,185,670,305);

-- ####################################################################
-- ########################### END FILE ################################
-- ####################################################################