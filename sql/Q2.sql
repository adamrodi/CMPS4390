/*
TEAM NAME: Mango
TEAM MEMBERS' NAME: Suyog Karki, Samiksha Gnawali, Adam Rodi


Instructions
- Descriptions must reflect a business operation's need
- One query for each item (Q..) is enough. E.g., for QD1: CREATE TABLE, write a DDL query to create one of your project's tables. Similar for the others.
- You must use the exact format
- Project a few attributes only unless otherwise said
- Do not change the order of the queries
*/


-- ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ QUERIES   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


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
