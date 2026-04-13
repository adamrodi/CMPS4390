import csv
from collections import defaultdict

def load_csv(filename):
    with open(filename, newline="", encoding="utf-8") as f:
        return list(csv.DictReader(f))

# Load data
users = load_csv("users.csv")
categories = load_csv("categories.csv")
products = load_csv("products.csv")
subscriptions = load_csv("subscriptions.csv")
payments = load_csv("payments.csv")
reviews = load_csv("reviews.csv")
seller_payouts = load_csv("seller_payouts.csv")
product_tags = load_csv("product_tags.csv")
tags = load_csv("tags.csv")

print("---- BASIC COUNTS ----")
print("Users:", len(users))
print("Products:", len(products))
print("Subscriptions:", len(subscriptions))
print("Payments:", len(payments))
print("Reviews:", len(reviews))
print("Seller Payouts:", len(seller_payouts))
print("Tags:", len(tags))
print("Product_Tags:", len(product_tags))
print()

# Lookup dictionaries
user_roles = {u["user_id"]: u["role"] for u in users}
products_by_id = {p["product_id"]: p for p in products}
subscriptions_by_id = {s["subscription_id"]: s for s in subscriptions}
tags_by_id = {t["tag_id"]: t for t in tags}

# --- CHECK 1: Products must reference valid sellers ---
invalid_sellers = [
    p for p in products
    if p["seller_id"] not in user_roles or user_roles[p["seller_id"]] != "seller"
]
print("Invalid seller references:", len(invalid_sellers))

# --- CHECK 2: Subscriptions must reference valid buyers ---
invalid_subs = [
    s for s in subscriptions
    if s["buyer_id"] not in user_roles or user_roles[s["buyer_id"]] != "buyer"
]
print("Invalid buyer subscriptions:", len(invalid_subs))

# --- CHECK 3: Subscriptions must reference valid products ---
invalid_sub_products = [
    s for s in subscriptions
    if s["product_id"] not in products_by_id
]
print("Invalid subscription product references:", len(invalid_sub_products))

# --- CHECK 4: Payments must reference valid subscriptions ---
invalid_payment_subs = [
    p for p in payments
    if p["subscription_id"] not in subscriptions_by_id
]
print("Invalid payment subscription references:", len(invalid_payment_subs))

# --- CHECK 5: Payment amount must equal product price ---
invalid_payment_amounts = []

for payment in payments:
    sub = subscriptions_by_id[payment["subscription_id"]]
    product = products_by_id[sub["product_id"]]
    expected_price = round(float(product["price"]), 2)
    actual_amount = round(float(payment["amount"]), 2)

    if actual_amount != expected_price:
        invalid_payment_amounts.append(payment)

print("Invalid payment amounts:", len(invalid_payment_amounts))

# --- CHECK 6: Commission must equal 20% ---
invalid_commissions = []

for payment in payments:
    amount = round(float(payment["amount"]), 2)
    expected_commission = round(amount * 0.20, 2)
    actual_commission = round(float(payment["commission"]), 2)

    if actual_commission != expected_commission:
        invalid_commissions.append(payment)

print("Invalid commissions:", len(invalid_commissions))

# --- CHECK 7: Seller earning must equal 80% ---
invalid_earnings = []

for payment in payments:
    amount = round(float(payment["amount"]), 2)
    expected_earning = round(amount * 0.80, 2)
    actual_earning = round(float(payment["seller_earning"]), 2)

    if actual_earning != expected_earning:
        invalid_earnings.append(payment)

print("Invalid seller earnings:", len(invalid_earnings))

# --- CHECK 8: Payment split consistency ---
invalid_split = [
    p for p in payments
    if round(float(p["amount"]), 2) !=
    round(float(p["commission"]) + float(p["seller_earning"]), 2)
]
print("Invalid payment splits:", len(invalid_split))

# --- CHECK 9: Seller payouts must equal sum of seller earnings ---
seller_earnings = defaultdict(float)

for payment in payments:
    sub = subscriptions_by_id[payment["subscription_id"]]
    product = products_by_id[sub["product_id"]]
    seller_id = product["seller_id"]
    seller_earnings[seller_id] += float(payment["seller_earning"])

invalid_payouts = []

for payout in seller_payouts:
    seller_id = payout["seller_id"]
    expected_total = round(seller_earnings[seller_id], 2)
    actual_total = round(float(payout["total_amount"]), 2)

    if actual_total != expected_total:
        invalid_payouts.append(payout)

print("Invalid seller payouts:", len(invalid_payouts))

# --- CHECK 10: Reviews must match valid subscription pairs ---
valid_pairs = {(s["buyer_id"], s["product_id"]) for s in subscriptions}

invalid_reviews = [
    r for r in reviews
    if (r["buyer_id"], r["product_id"]) not in valid_pairs
]
print("Invalid reviews:", len(invalid_reviews))

# --- CHECK 11: Product_Tags must not contain duplicates ---
seen_pairs = set()
duplicate_product_tags = []

for pt in product_tags:
    pair = (pt["product_id"], pt["tag_id"])
    if pair in seen_pairs:
        duplicate_product_tags.append(pt)
    seen_pairs.add(pair)

print("Duplicate product_tags:", len(duplicate_product_tags))

# --- CHECK 12: All foreign keys exist ---
invalid_fk = []

for pt in product_tags:
    if pt["product_id"] not in products_by_id or pt["tag_id"] not in tags_by_id:
        invalid_fk.append(pt)

print("Invalid product_tags foreign keys:", len(invalid_fk))

# --- CHECK 13: Each table includes at least one NULL-like value ---
def has_null_like(row):
    return any(v == "" or v is None for v in row.values())

tables = {
    "users": users,
    "categories": categories,
    "products": products,
    "subscriptions": subscriptions,
    "payments": payments,
    "reviews": reviews,
    "seller_payouts": seller_payouts,
    "tags": tags,
    "product_tags": product_tags,
}

print("\n---- NULL PRESENCE CHECK ----")
for name, rows in tables.items():
    null_count = sum(1 for row in rows if has_null_like(row))
    print(f"{name}: rows with NULL-like values = {null_count}")

if all(not has_null_like(row) for row in product_tags):
    print("NOTE: product_tags has no nullable attributes in current design.")
    print("      If your rubric strictly requires NULLs in every table, add one optional attribute.")

print("\n---- VERIFICATION COMPLETE ----")