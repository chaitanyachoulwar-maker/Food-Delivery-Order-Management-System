-- =====================================================================
--  Food Delivery Order Management System
--  Database schema (MySQL 8.0+) built from the ER diagram
--
--  Entities  : CUSTOMER, RESTAURANT, DELIVERY_PARTNER, ORDER,
--              ORDER_ITEM, FOOD_ITEM, PAYMENT
--  Relations : CUSTOMER         1 --PLACES-------- N ORDER
--              ORDER            N --FROM---------- 1 RESTAURANT
--              DELIVERY_PARTNER 1 --DELIVERED_BY-- N ORDER
--              ORDER            1 --CONTAINS------ N ORDER_ITEM
--              ORDER_ITEM       N --INCLUDES------ 1 FOOD_ITEM
--              FOOD_ITEM        N ---------------- 1 RESTAURANT (Restaurant_ID FK)
--              CUSTOMER         1 --HAS----------- N DELIVERY_PARTNER
--              DELIVERY_PARTNER 1 --DELIVERS------ N PAYMENT
--
--  Note: ORDER is a reserved word in SQL, so the table is named Orders.
-- =====================================================================

DROP DATABASE IF EXISTS food_delivery_db;
CREATE DATABASE food_delivery_db;
USE food_delivery_db;

-- ---------------------------------------------------------------------
-- 1. CUSTOMER
-- ---------------------------------------------------------------------
CREATE TABLE Customer (
    Customer_ID   INT           AUTO_INCREMENT PRIMARY KEY,
    Full_Name     VARCHAR(100)  NOT NULL,
    Email         VARCHAR(100)  NOT NULL UNIQUE,
    Phone_No      VARCHAR(15)   NOT NULL UNIQUE,
    Address       VARCHAR(255)  NOT NULL
);

-- ---------------------------------------------------------------------
-- 2. RESTAURANT
-- ---------------------------------------------------------------------
CREATE TABLE Restaurant (
    Restaurant_ID    INT           AUTO_INCREMENT PRIMARY KEY,
    Restaurant_Name  VARCHAR(100)  NOT NULL,
    Cuisine_Type     VARCHAR(50)   NOT NULL,
    Rating           DECIMAL(2,1)  DEFAULT 0.0,
    Address          VARCHAR(255)  NOT NULL,
    Phone_No         VARCHAR(15)   NOT NULL UNIQUE,
    CONSTRAINT chk_restaurant_rating CHECK (Rating BETWEEN 0 AND 5)
);

-- ---------------------------------------------------------------------
-- 3. DELIVERY_PARTNER
--    CUSTOMER 1 --HAS-- N DELIVERY_PARTNER  ->  Customer_ID FK
-- ---------------------------------------------------------------------
CREATE TABLE Delivery_Partner (
    Partner_ID    INT           AUTO_INCREMENT PRIMARY KEY,
    Full_Name     VARCHAR(100)  NOT NULL,
    Phone_No      VARCHAR(15)   NOT NULL UNIQUE,
    Email         VARCHAR(100)  NOT NULL UNIQUE,
    Vehicle_No    VARCHAR(20)   NOT NULL UNIQUE,
    Customer_ID   INT           NULL,
    CONSTRAINT fk_partner_customer
        FOREIGN KEY (Customer_ID) REFERENCES Customer (Customer_ID)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- 4. FOOD_ITEM
--    FOOD_ITEM N -- 1 RESTAURANT  ->  Restaurant_ID FK
-- ---------------------------------------------------------------------
CREATE TABLE Food_Item (
    Food_ID        INT            AUTO_INCREMENT PRIMARY KEY,
    Food_Name      VARCHAR(100)   NOT NULL,
    Category       VARCHAR(50)    NOT NULL,
    Price          DECIMAL(10,2)  NOT NULL,
    Description    VARCHAR(255),
    Restaurant_ID  INT            NOT NULL,
    CONSTRAINT chk_food_price CHECK (Price > 0),
    CONSTRAINT fk_food_restaurant
        FOREIGN KEY (Restaurant_ID) REFERENCES Restaurant (Restaurant_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- 5. ORDER  (table name: Orders)
--    CUSTOMER         1 --PLACES------- N ORDER  ->  Customer_ID FK
--    RESTAURANT       1 --FROM--------- N ORDER  ->  Restaurant_ID FK
--    DELIVERY_PARTNER 1 --DELIVERED_BY- N ORDER  ->  Partner_ID FK
-- ---------------------------------------------------------------------
CREATE TABLE Orders (
    Order_ID       INT            AUTO_INCREMENT PRIMARY KEY,
    Order_Date     DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Total_Amount   DECIMAL(10,2)  NOT NULL DEFAULT 0.00,
    Status         VARCHAR(20)    NOT NULL DEFAULT 'Placed',
    Customer_ID    INT            NOT NULL,
    Restaurant_ID  INT            NOT NULL,
    Partner_ID     INT            NULL,      -- assigned once a partner picks up the order
    CONSTRAINT chk_order_amount CHECK (Total_Amount >= 0),
    CONSTRAINT chk_order_status CHECK (Status IN
        ('Placed', 'Confirmed', 'Preparing', 'Out for Delivery', 'Delivered', 'Cancelled')),
    CONSTRAINT fk_order_customer
        FOREIGN KEY (Customer_ID) REFERENCES Customer (Customer_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_order_restaurant
        FOREIGN KEY (Restaurant_ID) REFERENCES Restaurant (Restaurant_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_order_partner
        FOREIGN KEY (Partner_ID) REFERENCES Delivery_Partner (Partner_ID)
        ON DELETE SET NULL ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- 6. ORDER_ITEM
--    ORDER     1 --CONTAINS-- N ORDER_ITEM  ->  Order_ID FK
--    FOOD_ITEM 1 --INCLUDES-- N ORDER_ITEM  ->  Food_ID FK
-- ---------------------------------------------------------------------
CREATE TABLE Order_Item (
    OrderItem_ID  INT            AUTO_INCREMENT PRIMARY KEY,
    Quantity      INT            NOT NULL,
    Unit_Price    DECIMAL(10,2)  NOT NULL,
    Total_Price   DECIMAL(10,2)  GENERATED ALWAYS AS (Quantity * Unit_Price) STORED,
    Order_ID      INT            NOT NULL,
    Food_ID       INT            NOT NULL,
    CONSTRAINT chk_item_quantity CHECK (Quantity > 0),
    CONSTRAINT chk_item_price    CHECK (Unit_Price > 0),
    CONSTRAINT fk_item_order
        FOREIGN KEY (Order_ID) REFERENCES Orders (Order_ID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_item_food
        FOREIGN KEY (Food_ID) REFERENCES Food_Item (Food_ID)
        ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- 7. PAYMENT
--    DELIVERY_PARTNER 1 --DELIVERS-- N PAYMENT  ->  Partner_ID FK
-- ---------------------------------------------------------------------
CREATE TABLE Payment (
    Payment_ID      INT            AUTO_INCREMENT PRIMARY KEY,
    Amount          DECIMAL(10,2)  NOT NULL,
    Payment_Method  VARCHAR(20)    NOT NULL,
    Payment_Date    DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    Payment_Status  VARCHAR(20)    NOT NULL DEFAULT 'Pending',
    Partner_ID      INT            NOT NULL,
    CONSTRAINT chk_payment_amount CHECK (Amount > 0),
    CONSTRAINT chk_payment_method CHECK (Payment_Method IN
        ('Cash', 'Card', 'UPI', 'Net Banking', 'Wallet')),
    CONSTRAINT chk_payment_status CHECK (Payment_Status IN
        ('Pending', 'Completed', 'Failed', 'Refunded')),
    CONSTRAINT fk_payment_partner
        FOREIGN KEY (Partner_ID) REFERENCES Delivery_Partner (Partner_ID)
        ON DELETE CASCADE ON UPDATE CASCADE
);

-- ---------------------------------------------------------------------
-- Indexes on foreign keys / frequently filtered columns
-- ---------------------------------------------------------------------
CREATE INDEX idx_orders_status     ON Orders (Status);
CREATE INDEX idx_orders_date       ON Orders (Order_Date);
CREATE INDEX idx_food_category     ON Food_Item (Category);
CREATE INDEX idx_payment_status    ON Payment (Payment_Status);


-- =====================================================================
--  SAMPLE DATA
-- =====================================================================

INSERT INTO Customer (Full_Name, Email, Phone_No, Address) VALUES
('Aarav Sharma',  'aarav.sharma@example.com',  '9876543210', '12 MG Road, Pune'),
('Priya Patel',   'priya.patel@example.com',   '9876543211', '45 FC Road, Pune'),
('Rahul Verma',   'rahul.verma@example.com',   '9876543212', '78 Baner Road, Pune'),
('Sneha Kulkarni','sneha.kulkarni@example.com','9876543213', '23 Kothrud, Pune'),
('Vikram Joshi',  'vikram.joshi@example.com',  '9876543214', '56 Viman Nagar, Pune');

INSERT INTO Restaurant (Restaurant_Name, Cuisine_Type, Rating, Address, Phone_No) VALUES
('Spice Garden',   'North Indian', 4.5, '10 JM Road, Pune',       '0201234561'),
('Dragon Wok',     'Chinese',      4.2, '22 Camp, Pune',          '0201234562'),
('Pizza Palace',   'Italian',      4.0, '5 Koregaon Park, Pune',  '0201234563'),
('Dosa Corner',    'South Indian', 4.7, '18 Deccan, Pune',        '0201234564');

INSERT INTO Delivery_Partner (Full_Name, Phone_No, Email, Vehicle_No, Customer_ID) VALUES
('Suresh Yadav',  '9123456780', 'suresh.yadav@example.com',  'MH12AB1234', 1),
('Ganesh Pawar',  '9123456781', 'ganesh.pawar@example.com',  'MH12CD5678', 2),
('Imran Shaikh',  '9123456782', 'imran.shaikh@example.com',  'MH14EF9012', 3),
('Anil Deshmukh', '9123456783', 'anil.deshmukh@example.com', 'MH12GH3456', 4);

INSERT INTO Food_Item (Food_Name, Category, Price, Description, Restaurant_ID) VALUES
('Paneer Butter Masala', 'Main Course', 250.00, 'Cottage cheese in rich tomato gravy', 1),
('Butter Naan',          'Bread',        40.00, 'Soft tandoor bread with butter',      1),
('Dal Makhani',          'Main Course', 200.00, 'Slow-cooked black lentils',           1),
('Veg Hakka Noodles',    'Main Course', 180.00, 'Stir-fried noodles with vegetables',  2),
('Manchurian',           'Starter',     160.00, 'Veg balls in spicy sauce',            2),
('Margherita Pizza',     'Pizza',       299.00, 'Classic tomato and mozzarella',       3),
('Garlic Bread',         'Starter',     129.00, 'Toasted bread with garlic butter',    3),
('Masala Dosa',          'Main Course', 120.00, 'Crispy dosa with potato filling',     4),
('Filter Coffee',        'Beverage',     50.00, 'Traditional South Indian coffee',     4);

INSERT INTO Orders (Order_Date, Total_Amount, Status, Customer_ID, Restaurant_ID, Partner_ID) VALUES
('2026-10-20 12:30:00', 530.00, 'Delivered',        1, 1, 1),
('2026-10-21 19:15:00', 340.00, 'Delivered',        2, 2, 2),
('2026-10-22 20:00:00', 557.00, 'Out for Delivery', 3, 3, 3),
('2026-10-23 08:45:00', 290.00, 'Preparing',        4, 4, NULL),
('2026-10-24 13:10:00', 200.00, 'Cancelled',        5, 1, NULL);

INSERT INTO Order_Item (Quantity, Unit_Price, Order_ID, Food_ID) VALUES
(1, 250.00, 1, 1),   -- Order 1: Paneer Butter Masala
(2,  40.00, 1, 2),   --          Butter Naan x2
(1, 200.00, 1, 3),   --          Dal Makhani
(1, 180.00, 2, 4),   -- Order 2: Veg Hakka Noodles
(1, 160.00, 2, 5),   --          Manchurian
(1, 299.00, 3, 6),   -- Order 3: Margherita Pizza
(2, 129.00, 3, 7),   --          Garlic Bread x2
(2, 120.00, 4, 8),   -- Order 4: Masala Dosa x2
(1,  50.00, 4, 9),   --          Filter Coffee
(1, 200.00, 5, 3);   -- Order 5: Dal Makhani

INSERT INTO Payment (Amount, Payment_Method, Payment_Date, Payment_Status, Partner_ID) VALUES
(530.00, 'UPI',  '2026-10-20 13:05:00', 'Completed', 1),
(340.00, 'Cash', '2026-10-21 19:50:00', 'Completed', 2),
(557.00, 'Card', '2026-10-22 20:05:00', 'Completed', 3),
(290.00, 'UPI',  '2026-10-23 08:50:00', 'Pending',   4);


-- =====================================================================
--  SAMPLE QUERIES
-- =====================================================================

-- 1. All orders with customer, restaurant and delivery partner names
SELECT o.Order_ID, o.Order_Date, c.Full_Name AS Customer,
       r.Restaurant_Name, dp.Full_Name AS Delivery_Partner,
       o.Total_Amount, o.Status
FROM Orders o
JOIN Customer   c  ON o.Customer_ID   = c.Customer_ID
JOIN Restaurant r  ON o.Restaurant_ID = r.Restaurant_ID
LEFT JOIN Delivery_Partner dp ON o.Partner_ID = dp.Partner_ID
ORDER BY o.Order_Date;

-- 2. Item-wise bill for a given order
SELECT oi.OrderItem_ID, f.Food_Name, oi.Quantity, oi.Unit_Price, oi.Total_Price
FROM Order_Item oi
JOIN Food_Item f ON oi.Food_ID = f.Food_ID
WHERE oi.Order_ID = 1;

-- 3. Check that each order's Total_Amount matches the sum of its items
SELECT o.Order_ID, o.Total_Amount, SUM(oi.Total_Price) AS Items_Total
FROM Orders o
JOIN Order_Item oi ON o.Order_ID = oi.Order_ID
GROUP BY o.Order_ID, o.Total_Amount;

-- 4. Menu of a restaurant
SELECT r.Restaurant_Name, f.Food_Name, f.Category, f.Price
FROM Food_Item f
JOIN Restaurant r ON f.Restaurant_ID = r.Restaurant_ID
WHERE r.Restaurant_Name = 'Spice Garden';

-- 5. Revenue per restaurant (excluding cancelled orders)
SELECT r.Restaurant_Name, COUNT(o.Order_ID) AS Total_Orders,
       SUM(o.Total_Amount) AS Revenue
FROM Restaurant r
LEFT JOIN Orders o ON r.Restaurant_ID = o.Restaurant_ID AND o.Status <> 'Cancelled'
GROUP BY r.Restaurant_ID, r.Restaurant_Name
ORDER BY Revenue DESC;

-- 6. Number of deliveries and payments collected per delivery partner
SELECT dp.Full_Name,
       (SELECT COUNT(*) FROM Orders o
         WHERE o.Partner_ID = dp.Partner_ID AND o.Status = 'Delivered') AS Deliveries,
       (SELECT COALESCE(SUM(p.Amount), 0) FROM Payment p
         WHERE p.Partner_ID = dp.Partner_ID AND p.Payment_Status = 'Completed') AS Amount_Collected
FROM Delivery_Partner dp;

-- 7. Top 3 best-selling food items
SELECT f.Food_Name, SUM(oi.Quantity) AS Qty_Sold
FROM Order_Item oi
JOIN Food_Item f ON oi.Food_ID = f.Food_ID
JOIN Orders o    ON oi.Order_ID = o.Order_ID
WHERE o.Status <> 'Cancelled'
GROUP BY f.Food_ID, f.Food_Name
ORDER BY Qty_Sold DESC
LIMIT 3;
