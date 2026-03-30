/*
TEAM NAME: Mango
TEAM MEMBERS' NAME: Adam Rodi, Samiksha Gnawali, Suyog karki


Instructions
- Descriptions must reflect a business operation's need
- One query for each item (Q..) is enough. E.g.,�for�QD1: CREATE TABLE, write a DDL query to create one of your project's tables. Similar for the others.
- You must use the exact format
- Project a few attributes only unless otherwise said
- Do not change the order of the queries
*/

-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ DDL QUERIES   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


-- Create and select the database
CREATE DATABASE AIMarketplace;
GO

USE AIMarketplace;
GO


--QD1: CREATE TABLE ...
/*
Instructions:
- Must define PK
- Must define a default value as needed
*/
----Description: Creates all 9 tables for the AI Marketplace platform to manage users, products, categories, tags, subscriptions, payments, reviews, and seller payouts.

-- Table 1: Users
CREATE TABLE Users (
    user_id        INT           PRIMARY KEY,
    first_name     VARCHAR(50)   NOT NULL,
    last_name      VARCHAR(50)   NOT NULL,
    email          VARCHAR(100)  NOT NULL UNIQUE,
    password_hash  VARCHAR(255)  NOT NULL,
    role           VARCHAR(10)   NOT NULL,
    created_at     DATETIME      DEFAULT GETDATE(),
    account_status VARCHAR(20)   DEFAULT 'active'
);
GO

-- Table 2: Categories
CREATE TABLE Categories (
    category_id   INT          PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL,
    description   VARCHAR(255) DEFAULT 'No description provided'
);
GO

-- Table 3: Tags
CREATE TABLE Tags (
    tag_id   INT          PRIMARY KEY,
    tag_name VARCHAR(50)  NOT NULL
);
GO

-- Table 4: Products
CREATE TABLE Products (
    product_id   INT            PRIMARY KEY,
    product_name VARCHAR(100)   NOT NULL,
    description  VARCHAR(255)   DEFAULT 'No description provided',
    product_type VARCHAR(20)    NOT NULL,
    price        DECIMAL(10,2)  NOT NULL,
    seller_id    INT            NOT NULL,
    category_id  INT            NOT NULL DEFAULT 1, 
    external_url VARCHAR(255)   DEFAULT 'N/A',
    status       VARCHAR(20)    DEFAULT 'active',
    created_at   DATETIME       DEFAULT GETDATE()
);
GO

-- Table 5: Product_Tags
CREATE TABLE Product_Tags (
    product_id INT NOT NULL,
    tag_id     INT NOT NULL,
    PRIMARY KEY (product_id, tag_id)
);
GO

-- Table 6: Subscriptions
CREATE TABLE Subscriptions (
    subscription_id INT          PRIMARY KEY,
    buyer_id        INT          NOT NULL,
    product_id      INT          NOT NULL,
    start_date      DATE         NOT NULL,
    end_date        DATE         DEFAULT NULL,
    status          VARCHAR(20)  DEFAULT 'active'
);
GO

-- Table 7: Payments
CREATE TABLE Payments (
    payment_id          INT           PRIMARY KEY,
    subscription_id     INT           NOT NULL,
    payment_date        DATE          NOT NULL,
    amount              DECIMAL(10,2) NOT NULL,
    platform_commission DECIMAL(10,2) NULL,
    seller_earning      DECIMAL(10,2) NULL
);
GO

-- Table 8: Reviews
CREATE TABLE Reviews (
    review_id   INT           PRIMARY KEY,
    product_id  INT           NOT NULL,
    buyer_id    INT           NOT NULL,
    rating      INT           NOT NULL,
    comment     VARCHAR(500)  DEFAULT 'No comment provided',
    review_date DATE          DEFAULT GETDATE()
);
GO

-- Table 9: Seller_Payouts
CREATE TABLE Seller_Payouts (
    payout_id     INT           PRIMARY KEY,
    seller_id     INT           NOT NULL,
    payout_date   DATE          NOT NULL,
    total_amount  DECIMAL(10,2) NOT NULL,
    payout_status VARCHAR(20)   DEFAULT 'pending'
);
GO



--QD2: ALTER TABLE ...
----Description: Adds a phone_number column to the Users table to store seller contact information on the platform.

ALTER TABLE Users
ADD phone_number VARCHAR(20) DEFAULT 'N/A';
GO



--QD3: ADD "CHECK" CONSTRAINT:
----Description: Ensures that a user's role can only be assigned as either 'buyer' or 'seller' on the platform.

ALTER TABLE Users
ADD CONSTRAINT chk_user_role 
CHECK (role IN ('buyer', 'seller'));
GO



--QD4: ADD FK CONSTRAINT(S) TO THE TABLE
/*
Instructions:
- Must define action
- At least one of the FKs must utilize the default value
*/
----Description: Adds foreign key constraints across all tables to enforce referential integrity.

-- Products: Users (seller)
ALTER TABLE Products
ADD CONSTRAINT fk_products_seller
    FOREIGN KEY (seller_id) REFERENCES Users(user_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE;
GO

-- Products:  Categories (uses SET DEFAULT - satisfies default value requirement)
ALTER TABLE Products
ADD CONSTRAINT fk_products_category
    FOREIGN KEY (category_id) REFERENCES Categories(category_id)
    ON DELETE SET DEFAULT
    ON UPDATE CASCADE;
GO

-- Subscriptions: Users (buyer)
ALTER TABLE Subscriptions
ADD CONSTRAINT fk_subscriptions_buyer
    FOREIGN KEY (buyer_id) REFERENCES Users(user_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
GO

-- Subscriptions: Products
ALTER TABLE Subscriptions
ADD CONSTRAINT fk_subscriptions_product
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
GO

-- Payments: Subscriptions
ALTER TABLE Payments
ADD CONSTRAINT fk_payments_subscription
    FOREIGN KEY (subscription_id) REFERENCES Subscriptions(subscription_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE;
GO

-- Reviews: Products
ALTER TABLE Reviews
ADD CONSTRAINT fk_reviews_product
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
GO

-- Reviews: Users (buyer)
ALTER TABLE Reviews
ADD CONSTRAINT fk_reviews_buyer
    FOREIGN KEY (buyer_id) REFERENCES Users(user_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;
GO

-- Seller_Payouts: Users (seller)
ALTER TABLE Seller_Payouts
ADD CONSTRAINT fk_payouts_seller
    FOREIGN KEY (seller_id) REFERENCES Users(user_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE;
GO

-- Product_Tags: Products
ALTER TABLE Product_Tags
ADD CONSTRAINT fk_producttags_product
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE;
GO

-- Product_Tags: Tags
ALTER TABLE Product_Tags
ADD CONSTRAINT fk_producttags_tag
    FOREIGN KEY (tag_id) REFERENCES Tags(tag_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE;
GO



--QD5: Create TRIGGER ...
----Description: Automatically calculates and sets the platform commission (20%) and seller earning (80%) whenever a new payment is inserted into the Payments table.

CREATE TRIGGER trg_calculate_commission
ON Payments
AFTER INSERT
AS
BEGIN
    UPDATE Payments
    SET 
        platform_commission = ROUND(i.amount * 0.20, 2),
        seller_earning      = ROUND(i.amount * 0.80, 2)
    FROM Payments p
    INNER JOIN inserted i ON p.payment_id = i.payment_id;
END;
GO



-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ DML QUERIES   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


--QM1.1: A TEST QUERY FOR THE TRIGGER CREATED in QD5:
----Description: Inserts a test payment with only the amount provided to verify that the trigger automatically calculates and sets the platform commission (20%) and seller earning (80%).

-- Insert minimal required data to satisfy FK chain
INSERT INTO Users (user_id, first_name, last_name, email, password_hash, role)
VALUES (1, 'Test', 'Seller', 'seller@test.com', 'hashedpw123', 'seller');

INSERT INTO Users (user_id, first_name, last_name, email, password_hash, role)
VALUES (2, 'Test', 'Buyer', 'buyer@test.com', 'hashedpw456', 'buyer');

INSERT INTO Categories (category_id, category_name)
VALUES (1, 'Text Generation');

INSERT INTO Products (product_id, product_name, product_type, price, seller_id, category_id)
VALUES (1, 'Test AI Tool', 'web_app', 100.00, 1, 1);

INSERT INTO Subscriptions (subscription_id, buyer_id, product_id, start_date)
VALUES (1, 2, 1, '2026-03-29');

-- Insert payment WITHOUT commission and earning to test trigger
INSERT INTO Payments (payment_id, subscription_id, payment_date, amount)
VALUES (1, 1, '2026-03-29', 200.00);

-- Verify trigger auto-calculated commission and earning
SELECT payment_id, amount, platform_commission, seller_earning
FROM Payments
WHERE payment_id = 1;



--QM1.2: A TEST QUERY FOR THE "CHECK" CONSTRAINT DEFINED in QD3:
----Description: Attempts to insert a user with an invalid role to verify that the check constraint correctly rejects any role value other than 'buyer' or 'seller'.

-- This INSERT should FAIL due to chk_user_role constraint
INSERT INTO Users (user_id, first_name, last_name, email, password_hash, role)
VALUES (3, 'Test', 'Admin', 'admin@test.com', 'hashedpw789', 'admin');



--QM1.3: A TEST QUERY FOR THE FK CONSTRAINT DEFINED in QD4:
----Description: Attempts to insert a product referencing a non-existent seller to verify that the foreign key constraint correctly prevents invalid data from being inserted into the Products table.

-- This INSERT should FAIL due to fk_products_seller constraint
INSERT INTO Products (product_id, product_name, product_type, price, seller_id, category_id)
VALUES (99, 'Fake Product', 'web_app', 50.00, 9999, 1);


--QM2: INSERT DATA:
----Description: .....................


--QM3: UPDATE DATA:
----Description: .....................


--QM4: DELETE DATA:
----Description: .....................



--QM5: QUERY DATA WITH WHERE CLAUSE:
----Description: .....................



--QM6.1: QUERY DATA WITH 'SUB-QUERY IN WHERE CLAUSE':
----Description: .....................


--QM6.2: QUERY DATA WITH SUB-QUERY IN FROM CLAUSE:
----Description: .....................



--QM6.3: QUERY DATA WITH 'SUB-QUERY IN SELECT CLAUSE':
----Description: .....................



--QM7: QUERY DATA WITH EXCEPT:
----Description: .....................


--QM8.1: QUERY DATA WITH ANY/SOME:
----Description: .....................


--QM8.2: QUERY DATA WITH ALL in front of a sub-query:
----Description: .....................


--QM9.1: INNER-JOIN-QUERY WITH WHERE CLAUSE:
----Description: .....................


--QM9.2: LEFT-OUTER-JOIN-QUERY WITH WHERE CLAUSE:
----Instruction: The query must return NULL DUE TO MISMATCHING TUPLES during the outer join:
----Description: .....................


--QM9.3: RIGHT-OUTER-JOIN-QUERY WITH WHERE CLAUSE:
----Instruction: The query must return NULL DUE TO MISMATCHING TUPLES during the outer join:
----Description: .....................


--QM9.4: FULL-OUTER-JOIN-QUERY WITH WHERE CLAUSE:
----Instruction: The query must return NULL DUE TO MISMATCHING TUPLES from LEFT and RIGHT tables due to the outer join:
----Description: .....................


--QM10.1: AGGREGATION-JOIN-QUERY WITH GROUP BY & HAVING:
----Description: .....................


--QM10.2: AGGREGATION-JOIN-QUERY WITH SUB-QUERY:
----Description: .....................



--QM11: WITH-QUERY:
----Description: .....................




