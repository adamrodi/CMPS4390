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
----Description: Processes a buyer's payment for a subscription by inserting only the transaction amount, relying on the platform trigger to automatically split the revenue into a 20% platform commission and 80% seller earning.

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



--QM1.2: A TEST QUERY FOR THE "CHECK" CONSTRAINT DEFINED in QD3:
----Description: Confirms the platform's role integrity rule by attempting to register a user with an unauthorized role, ensuring only 'buyer' and 'seller' accounts can be created on the marketplace.

-- This INSERT should FAIL due to chk_user_role constraint
INSERT INTO Users (user_id, first_name, last_name, email, password_hash, role)
VALUES (3, 'Test', 'Admin', 'admin@test.com', 'hashedpw789', 'admin');



--QM1.3: A TEST QUERY FOR THE FK CONSTRAINT DEFINED in QD4:
----Description: Confirms that a product cannot be listed on the marketplace without a valid registered seller, preventing orphaned listings that would have no owner to receive payouts.

-- This INSERT should FAIL due to fk_products_seller constraint
INSERT INTO Products (product_id, product_name, product_type, price, seller_id, category_id)
VALUES (99, 'Fake Product', 'web_app', 50.00, 9999, 1);


--QM2: INSERT DATA:
----Description: Populates the marketplace with additional sellers, buyers, categories, AI products, subscriptions, payments, reviews, tags, and seller payouts to represent a realistic set of platform activity.

-- Additional sellers and buyers
INSERT INTO Users (user_id, first_name, last_name, email, password_hash, role)
VALUES
    (3, 'Alice', 'Chen',  'alice@aimarket.com', 'hash_alice', 'seller'),
    (4, 'Bob',   'Patel', 'bob@aimarket.com',   'hash_bob',   'seller'),
    (5, 'Carol', 'Smith', 'carol@aimarket.com', 'hash_carol', 'buyer'),
    (6, 'David', 'Lee',   'david@aimarket.com', 'hash_david', 'buyer');

-- Additional categories
INSERT INTO Categories (category_id, category_name)
VALUES
    (2, 'Image Generation'),
    (3, 'Code Assistant');

-- Tags
INSERT INTO Tags (tag_id, tag_name)
VALUES
    (1, 'NLP'),
    (2, 'Computer Vision'),
    (3, 'Code Generation');

-- Additional products
INSERT INTO Products (product_id, product_name, product_type, price, seller_id, category_id)
VALUES
    (2, 'ImageCraft AI', 'web_app',     49.99,  3, 2),
    (3, 'CodeBot Pro',   'api_service', 79.99,  4, 3),
    (4, 'TextMaster',    'web_app',     29.99,  3, 1),
    (5, 'VisionPro',     'api_service', 129.99, 4, 2);

-- Product tags
INSERT INTO Product_Tags (product_id, tag_id)
VALUES (1, 1), (2, 2), (3, 3), (4, 1), (5, 2);

-- Additional subscriptions
INSERT INTO Subscriptions (subscription_id, buyer_id, product_id, start_date)
VALUES
    (2, 5, 2, '2026-01-10'),
    (3, 6, 3, '2026-01-15'),
    (4, 5, 3, '2026-02-01'),
    (5, 2, 4, '2026-02-05');

-- Additional payments (trigger auto-fills platform_commission and seller_earning)
INSERT INTO Payments (payment_id, subscription_id, payment_date, amount)
VALUES
    (2, 2, '2026-01-10', 49.99),
    (3, 3, '2026-01-15', 79.99),
    (4, 4, '2026-02-01', 79.99),
    (5, 5, '2026-02-05', 29.99);

-- Reviews
INSERT INTO Reviews (review_id, product_id, buyer_id, rating, comment)
VALUES
    (1, 1, 2, 5, 'Excellent AI tool!'),
    (2, 2, 5, 4, 'Great image quality.'),
    (3, 3, 6, 5, 'Saved hours of coding.'),
    (4, 4, 2, 3, 'Decent text generation.');

-- Seller payouts (seller 4 intentionally has no payout row)
INSERT INTO Seller_Payouts (payout_id, seller_id, payout_date, total_amount, payout_status)
VALUES
    (1, 1, '2026-03-01', 160.00, 'completed'),
    (2, 3, '2026-03-01',  63.99, 'pending');



--QM3: UPDATE DATA:
----Description: Marks all pending seller payouts older than 30 days as completed to reflect disbursements that have been successfully processed by the platform.

UPDATE Seller_Payouts
SET payout_status = 'completed'
WHERE payout_status = 'pending'
  AND payout_date <= DATEADD(DAY, -30, GETDATE());



--QM4: DELETE DATA:
----Description: Removes a buyer's review that was submitted in error for a product they did not use long enough to evaluate, maintaining rating accuracy on the platform.

DELETE FROM Reviews
WHERE review_id = 4;



--QM5: QUERY DATA WITH WHERE CLAUSE:
----Description: Retrieves all active products priced above $75 to help buyers browse the platform's premium AI tool offerings.

SELECT product_id, product_name, price, product_type, seller_id
FROM Products
WHERE price > 75.00
  AND status = 'active';



--QM6.1: QUERY DATA WITH 'SUB-QUERY IN WHERE CLAUSE':
----Description: Retrieves all buyers who hold an active subscription to at least one Code Assistant product to identify the platform's active developer user base.

SELECT user_id, first_name, last_name, email
FROM Users
WHERE role = 'buyer'
  AND user_id IN (
      SELECT s.buyer_id
      FROM Subscriptions s
      JOIN Products   p ON s.product_id  = p.product_id
      JOIN Categories c ON p.category_id = c.category_id
      WHERE c.category_name = 'Code Assistant'
        AND s.status = 'active'
  );



--QM6.2: QUERY DATA WITH SUB-QUERY IN FROM CLAUSE:
----Description: Displays each listed product alongside its average customer rating to help the platform surface high-performing AI tools for its featured section.

SELECT p.product_id, p.product_name, p.price, avg_r.avg_rating
FROM Products p
JOIN (
    SELECT product_id,
           ROUND(AVG(CAST(rating AS DECIMAL(5,2))), 2) AS avg_rating
    FROM Reviews
    GROUP BY product_id
) AS avg_r ON p.product_id = avg_r.product_id;



--QM6.3: QUERY DATA WITH 'SUB-QUERY IN SELECT CLAUSE':
----Description: Lists every seller account alongside the number of AI products they have published, giving the platform a quick view of individual seller activity levels.

SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    (SELECT COUNT(*)
     FROM Products p
     WHERE p.seller_id = u.user_id) AS product_count
FROM Users u
WHERE u.role = 'seller';



--QM7: QUERY DATA WITH EXCEPT:
----Description: Identifies sellers who have published products but have never received a payout, flagging accounts that may be owed earnings by the platform.

SELECT u.user_id, u.first_name, u.last_name
FROM Users u
WHERE u.role = 'seller'
EXCEPT
SELECT u.user_id, u.first_name, u.last_name
FROM Users u
JOIN Seller_Payouts sp ON u.user_id = sp.seller_id;



--QM8.1: QUERY DATA WITH ANY/SOME:
----Description: Finds all products priced higher than at least one Text Generation product, helping buyers compare costs against the platform's baseline AI text tools.

SELECT product_id, product_name, price, product_type
FROM Products
WHERE price > ANY (
    SELECT p.price
    FROM Products   p
    JOIN Categories c ON p.category_id = c.category_id
    WHERE c.category_name = 'Text Generation'
);



--QM8.2: QUERY DATA WITH ALL in front of a sub-query:
----Description: Retrieves products whose price exceeds every Text Generation product on the platform, identifying the most premium AI tools relative to the text-generation tier.

SELECT product_id, product_name, price, product_type
FROM Products
WHERE price > ALL (
    SELECT p.price
    FROM Products   p
    JOIN Categories c ON p.category_id = c.category_id
    WHERE c.category_name = 'Text Generation'
);


--QM9.1: INNER-JOIN-QUERY WITH WHERE CLAUSE:
----Description: Retrieves each active subscriber's name alongside the product they purchased and the platform's commission split for that payment, giving finance a breakdown of revenue for premium-priced subscriptions.

SELECT u.first_name, u.last_name,
       p.product_name, p.price,
       pay.amount, pay.platform_commission, pay.seller_earning
FROM Payments pay
INNER JOIN Subscriptions s ON pay.subscription_id = s.subscription_id
INNER JOIN Users u         ON s.buyer_id           = u.user_id
INNER JOIN Products p      ON s.product_id         = p.product_id
WHERE p.price > 30.00
  AND s.status = 'active';



--QM9.2: LEFT-OUTER-JOIN-QUERY WITH WHERE CLAUSE:
----Instruction: The query must return NULL DUE TO MISMATCHING TUPLES during the outer join:
----Description: Lists every seller account together with their payout record so the platform can audit which sellers have never received a payout; sellers with no matching payout row appear with NULL in all payout columns.

SELECT u.user_id, u.first_name, u.last_name,
       sp.payout_id, sp.total_amount, sp.payout_status
FROM Users u
LEFT OUTER JOIN Seller_Payouts sp ON u.user_id = sp.seller_id
WHERE u.role = 'seller';



--QM9.3: RIGHT-OUTER-JOIN-QUERY WITH WHERE CLAUSE:
----Instruction: The query must return NULL DUE TO MISMATCHING TUPLES during the outer join:
----Description: Displays all active products alongside any reviews they have received so the platform can identify listings with no reviews; products with no reviews appear with NULL in all review columns.

SELECT r.review_id, r.rating, r.comment,
       p.product_id, p.product_name, p.price
FROM Reviews r
RIGHT OUTER JOIN Products p ON r.product_id = p.product_id
WHERE p.status = 'active';



--QM9.4: FULL-OUTER-JOIN-QUERY WITH WHERE CLAUSE:
----Instruction: The query must return NULL DUE TO MISMATCHING TUPLES from LEFT and RIGHT tables due to the outer join:
----Description: Compares buyer review activity against seller payout records to confirm that no single account is simultaneously earning payouts and submitting reviews, ensuring role integrity across all platform users.

SELECT r.review_id, r.buyer_id,  r.rating,
       sp.payout_id, sp.seller_id, sp.total_amount
FROM Reviews r
FULL OUTER JOIN Seller_Payouts sp ON r.buyer_id = sp.seller_id
WHERE r.review_id IS NOT NULL OR sp.payout_id IS NOT NULL;



--QM10.1: AGGREGATION-JOIN-QUERY WITH GROUP BY & HAVING:
----Description: Calculates total earnings and payment count per seller to identify high-performing sellers who have collectively earned more than $50 in seller earnings, helping the platform prioritize support and promotional resources.

SELECT u.user_id, u.first_name, u.last_name,
       COUNT(pay.payment_id)   AS total_payments,
       SUM(pay.seller_earning) AS total_earned
FROM Users u
JOIN Products p      ON u.user_id          = p.seller_id
JOIN Subscriptions s ON p.product_id       = s.product_id
JOIN Payments pay    ON s.subscription_id  = pay.subscription_id
WHERE u.role = 'seller'
GROUP BY u.user_id, u.first_name, u.last_name
HAVING SUM(pay.seller_earning) > 50.00;



--QM10.2: AGGREGATION-JOIN-QUERY WITH SUB-QUERY:
----Description: Surfaces products whose average customer rating exceeds the platform-wide average rating, giving the marketplace's featured-products algorithm a list of objectively above-average AI tools.

SELECT p.product_id, p.product_name, p.price,
       product_avg.avg_rating,
       product_avg.review_count
FROM Products p
JOIN (
    SELECT product_id,
           ROUND(AVG(CAST(rating AS DECIMAL(5,2))), 2) AS avg_rating,
           COUNT(*)                                     AS review_count
    FROM Reviews
    GROUP BY product_id
) AS product_avg ON p.product_id = product_avg.product_id
WHERE product_avg.avg_rating > (
    SELECT AVG(CAST(rating AS DECIMAL(5,2)))
    FROM Reviews
);



--QM11: WITH-QUERY:
----Description: Uses a CTE to rank sellers by total earnings so the platform can identify top contributors for tiered incentive payouts.

WITH SellerRevenue AS (
    SELECT u.user_id, u.first_name, u.last_name,
           SUM(pay.seller_earning) AS total_seller_earning
    FROM Users u
    JOIN Products p      ON u.user_id         = p.seller_id
    JOIN Subscriptions s ON p.product_id      = s.product_id
    JOIN Payments pay    ON s.subscription_id = pay.subscription_id
    WHERE u.role = 'seller'
    GROUP BY u.user_id, u.first_name, u.last_name
)
SELECT user_id, first_name, last_name,
       total_seller_earning,
       RANK() OVER (ORDER BY total_seller_earning DESC) AS earning_rank
FROM SellerRevenue;




