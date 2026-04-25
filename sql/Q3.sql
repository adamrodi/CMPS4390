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
