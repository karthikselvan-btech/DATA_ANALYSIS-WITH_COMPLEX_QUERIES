create database if not exists Online_Retail_Store_Database;
use Online_Retail_Store_Database;

-- Products Table
CREATE TABLE Products (
    ProductID INT AUTO_INCREMENT PRIMARY KEY,
    ProductName VARCHAR(100) NOT NULL,
    Category VARCHAR(50),
    Price DECIMAL(10, 2) NOT NULL,
    StockQuantity INT NOT NULL
);

-- Customers Table
CREATE TABLE Customers (
    CustomerID INT AUTO_INCREMENT PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Phone VARCHAR(15),
    Address TEXT
);

-- Orders Table
CREATE TABLE Orders (
    OrderID INT AUTO_INCREMENT PRIMARY KEY,
    CustomerID INT NOT NULL,
    OrderDate DATE NOT NULL,
    TotalAmount DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

-- OrderDetails Table
CREATE TABLE OrderDetails (
    OrderDetailID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- Payments Table
CREATE TABLE Payments (
    PaymentID INT AUTO_INCREMENT PRIMARY KEY,
    OrderID INT NOT NULL,
    PaymentDate DATE NOT NULL,
    PaymentMethod VARCHAR(50),
    AmountPaid DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
);

-- Queries

-- 1.Insert a New Customer
INSERT INTO Customers (FirstName, LastName, Email, Phone, Address)
VALUES ('karthik', 'selvan', 'karthik.selvan@example.com', '1234567890', '123 car Street');

-- 2.Add a New Product
INSERT INTO Products (ProductName, Category, Price, StockQuantity)
VALUES ('Wireless Mouse', 'Electronics', 25.99, 100);

-- 3.Place a New Order

-- Step 1: Insert the order
INSERT INTO Orders (CustomerID, OrderDate, TotalAmount)
VALUES (1, '2024-12-17', 51.98);

-- Step 2: Get the last inserted OrderID
SET @OrderID = LAST_INSERT_ID();

-- Step 3: Insert order details
INSERT INTO OrderDetails (OrderID, ProductID, Quantity, Price)
VALUES (@OrderID, 1, 2, 25.99);

-- Step 4: Update product stock
UPDATE Products
SET StockQuantity = StockQuantity - 2
WHERE ProductID = 1;

-- 4.Process a Payment
INSERT INTO Payments (OrderID, PaymentDate, PaymentMethod, AmountPaid)
VALUES (1, '2024-12-17', 'Credit Card', 51.98);

-- Here are some examples of SQL queries using 
-- advanced techniques like window functions, subqueries, and Common Table Expressions (CTEs) 
-- for analyzing trends and patterns in your database schema.

-- 5. Top 3 Products by Sales Per Month (Using Window Functions)

WITH MonthlySales AS (
    SELECT 
        P.ProductName,
        DATE_FORMAT(O.OrderDate, '%Y-%m') AS SaleMonth,
        SUM(OD.Quantity * OD.Price) AS TotalSales,
        RANK() OVER (PARTITION BY DATE_FORMAT(O.OrderDate, '%Y-%m') ORDER BY SUM(OD.Quantity * OD.Price) DESC) AS SalesRank
    FROM 
        OrderDetails OD
    JOIN Products P ON OD.ProductID = P.ProductID
    JOIN Orders O ON OD.OrderID = O.OrderID
    GROUP BY P.ProductName, SaleMonth
)
SELECT * 
FROM MonthlySales
WHERE SalesRank <= 3
ORDER BY SaleMonth, SalesRank;

-- 6. Total Revenue and Percentage Contribution by Category (Using Window Functions)
SELECT 
    P.Category,
    SUM(OD.Quantity * OD.Price) AS TotalRevenue,
    SUM(SUM(OD.Quantity * OD.Price)) OVER () AS TotalStoreRevenue,
    ROUND(SUM(OD.Quantity * OD.Price) * 100.0 / SUM(SUM(OD.Quantity * OD.Price)) OVER (), 2) AS PercentageContribution
FROM 
    OrderDetails OD
JOIN Products P ON OD.ProductID = P.ProductID
GROUP BY P.Category
ORDER BY TotalRevenue DESC;

-- 7. Repeat Customers (Using Subqueries)
SELECT 
    C.CustomerID,
    CONCAT(C.FirstName, ' ', C.LastName) AS CustomerName,
    COUNT(DISTINCT O.OrderID) AS TotalOrders
FROM 
    Customers C
JOIN Orders O ON C.CustomerID = O.CustomerID
WHERE C.CustomerID IN (
    SELECT CustomerID
    FROM Orders
    GROUP BY CustomerID
    HAVING COUNT(OrderID) > 1
)
GROUP BY C.CustomerID, CustomerName
ORDER BY TotalOrders DESC;

-- 8. Low Stock Alert (Using CTE and Conditional Aggregation)
WITH LowStock AS (
    SELECT 
        ProductID,
        ProductName,
        StockQuantity
    FROM Products
    WHERE StockQuantity < 10
)
SELECT 
    ProductName,
    StockQuantity,
    CASE 
        WHEN StockQuantity = 0 THEN 'Out of Stock'
        WHEN StockQuantity < 5 THEN 'Critical Stock'
        ELSE 'Low Stock'
    END AS StockStatus
FROM LowStock
ORDER BY StockQuantity;

-- 9.Monthly Revenue Trends (Using CTE and Aggregation)
WITH RevenueTrend AS (
    SELECT 
        DATE_FORMAT(OrderDate, '%Y-%m') AS SaleMonth,
        SUM(TotalAmount) AS MonthlyRevenue
    FROM Orders
    GROUP BY SaleMonth
)
SELECT 
    SaleMonth,
    MonthlyRevenue,
    LAG(MonthlyRevenue) OVER (ORDER BY SaleMonth) AS PreviousMonthRevenue,
    ROUND((MonthlyRevenue - LAG(MonthlyRevenue) OVER (ORDER BY SaleMonth)) * 100.0 / LAG(MonthlyRevenue) OVER (ORDER BY SaleMonth), 2) AS PercentageChange
FROM RevenueTrend;

-- 10.Top Spending Customers (Using Window Functions and CTE)
WITH CustomerSpending AS (
    SELECT 
        C.CustomerID,
        CONCAT(C.FirstName, ' ', C.LastName) AS CustomerName,
        SUM(O.TotalAmount) AS TotalSpent,
        RANK() OVER (ORDER BY SUM(O.TotalAmount) DESC) AS SpendingRank
    FROM Customers C
    JOIN Orders O ON C.CustomerID = O.CustomerID
    GROUP BY C.CustomerID, CustomerName
)
SELECT * 
FROM CustomerSpending
WHERE SpendingRank <= 10
ORDER BY SpendingRank;

-- 11.Most Popular Payment Methods (Using Aggregation and Ranking)
SELECT 
    PaymentMethod,
    COUNT(PaymentID) AS TotalPayments,
    RANK() OVER (ORDER BY COUNT(PaymentID) DESC) AS PopularityRank
FROM Payments
GROUP BY PaymentMethod
ORDER BY PopularityRank;






