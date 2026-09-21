-- 1. Create Database
DROP DATABASE IF EXISTS ecommerce_db;
CREATE DATABASE ecommerce_db;
USE ecommerce_db;

-- 2. Customers Table
CREATE TABLE Customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(15),
    city VARCHAR(50),
    join_date DATE
);

-- 3. Products Table
CREATE TABLE Products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2),
    stock INT
);

-- 4. Orders Table
CREATE TABLE Orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    total_amount DECIMAL(10,2),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

-- 5. Order Details Table
CREATE TABLE OrderDetails (
    orderdetail_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    product_id INT,
    quantity INT,
    subtotal DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- 6. Payments Table
CREATE TABLE Payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    payment_method VARCHAR(50),
    payment_status VARCHAR(20),
    payment_date DATE,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);

-- -----------------------------
-- Insert Sample Data
-- -----------------------------

-- Customers
INSERT INTO Customers (name, email, phone, city, join_date) VALUES
('Amit Sharma', 'amit@gmail.com', '9876543210', 'Delhi', '2024-01-15'),
('Neha Verma', 'neha@gmail.com', '9876543211', 'Mumbai', '2024-02-10'),
('Rahul Gupta', 'rahul@gmail.com', '9876543212', 'Bangalore', '2024-03-05'),
('Priya Singh', 'priya@gmail.com', '9876543213', 'Chennai', '2024-04-20'),
('Karan Mehta', 'karan@gmail.com', '9876543214', 'Kolkata', '2024-05-01');

-- Products
INSERT INTO Products (name, category, price, stock) VALUES
('iPhone 15', 'Electronics', 80000, 10),
('Samsung TV', 'Electronics', 55000, 5),
('Nike Shoes', 'Fashion', 5000, 20),
('Levi’s Jeans', 'Fashion', 3000, 15),
('Cooking Oil', 'Groceries', 200, 50);

-- Orders
INSERT INTO Orders (customer_id, order_date, total_amount) VALUES
(1, '2024-06-10', 85000),
(2, '2024-06-12', 55000),
(3, '2024-07-05', 8000),
(1, '2024-08-15', 5200),
(4, '2024-08-20', 200);

-- Order Details
INSERT INTO OrderDetails (order_id, product_id, quantity, subtotal) VALUES
(1, 1, 1, 80000),
(1, 3, 1, 5000),
(2, 2, 1, 55000),
(3, 3, 1, 5000),
(3, 4, 1, 3000),
(4, 4, 2, 6000),
(5, 5, 1, 200);

-- Payments
INSERT INTO Payments (order_id, payment_method, payment_status, payment_date) VALUES
(1, 'UPI', 'Success', '2024-06-10'),
(2, 'Credit Card', 'Success', '2024-06-12'),
(3, 'UPI', 'Failed', '2024-07-05'),
(4, 'Debit Card', 'Success', '2024-08-15'),
(5, 'Cash on Delivery', 'Success', '2024-08-20');

-- -----------------------------
-- Queries for Insights
-- -----------------------------

-- 1. Top 5 Customers by Spending
SELECT c.name, SUM(o.total_amount) AS total_spent
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.name
ORDER BY total_spent DESC
LIMIT 5;

-- 2. Most Sold Product
SELECT p.name, SUM(od.quantity) AS total_sold
FROM Products p
JOIN OrderDetails od ON p.product_id = od.product_id
GROUP BY p.name
ORDER BY total_sold DESC
LIMIT 1;

-- 3. Monthly Revenue Trend
SELECT DATE_FORMAT(order_date, '%Y-%m') AS month, SUM(total_amount) AS revenue
FROM Orders
GROUP BY month
ORDER BY month;

-- 4. Customers Inactive for 6 Months
SELECT name, email
FROM Customers
WHERE customer_id NOT IN (
    SELECT DISTINCT customer_id FROM Orders 
    WHERE order_date > DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
);

-- 5. Payment Success Rate
SELECT payment_status, COUNT(*) AS count
FROM Payments
GROUP BY payment_status;

-- -----------------------------
-- Advanced SQL Features
-- -----------------------------

-- Stored Procedure: Place Order & Update Stock
DELIMITER //
CREATE PROCEDURE PlaceOrder(
    IN cust_id INT, IN prod_id INT, IN qty INT, IN method VARCHAR(50)
)
BEGIN
    DECLARE price DECIMAL(10,2);
    DECLARE total DECIMAL(10,2);

    -- Get product price
    SELECT price INTO price FROM Products WHERE product_id = prod_id;

    SET total = price * qty;

    -- Insert into Orders
    INSERT INTO Orders(customer_id, order_date, total_amount) 
    VALUES(cust_id, CURDATE(), total);

    SET @last_order_id = LAST_INSERT_ID();

    -- Insert into OrderDetails
    INSERT INTO OrderDetails(order_id, product_id, quantity, subtotal)
    VALUES(@last_order_id, prod_id, qty, total);

    -- Insert into Payments (default Success for demo)
    INSERT INTO Payments(order_id, payment_method, payment_status, payment_date)
    VALUES(@last_order_id, method, 'Success', CURDATE());
END //
DELIMITER ;

-- Trigger: Prevent Negative Stock
DELIMITER //
CREATE TRIGGER check_stock
BEFORE INSERT ON OrderDetails
FOR EACH ROW
BEGIN
    DECLARE available INT;
    SELECT stock INTO available FROM Products WHERE product_id = NEW.product_id;
    IF available < NEW.quantity THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Not enough stock available!';
    ELSE
        UPDATE Products SET stock = stock - NEW.quantity WHERE product_id = NEW.product_id;
    END IF;
END //
DELIMITER ;

-- View: Customer Purchase Summary
CREATE VIEW CustomerSummary AS
SELECT c.name, COUNT(o.order_id) AS total_orders, SUM(o.total_amount) AS total_spent
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
GROUP BY c.name;
