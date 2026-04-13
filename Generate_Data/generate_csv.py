import csv
import hashlib
import random
from faker import Faker

fake = Faker()

NUM_USERS = 100
NUM_SELLERS = 40
NUM_PRODUCTS = 50
NUM_SUBSCRIPTIONS = 200
NUM_PAYMENTS = 300


def maybe_null(value, probability=0.1):
    return "" if random.random() < probability else value


def write_csv(filename, rows):
    with open(filename, "w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)
    print(f"{filename} generated successfully.")


# Users
users = []
for i in range(1, NUM_USERS + 1):
    role = "seller" if i <= NUM_SELLERS else "buyer"
    password_hash = hashlib.sha256(fake.password(length=12).encode("utf-8")).hexdigest()

    users.append(
        {
            "user_id": i,
            "first_name": fake.first_name(),
            "last_name": maybe_null(fake.last_name(), 0.08),
            "email": fake.unique.email(),
            "password_hash": password_hash,
            "role": role,
            "created_at": fake.date_time_this_year().isoformat(),
            "account_status": maybe_null(random.choice(["active", "inactive", "suspended"]), 0.08),
        }
    )

write_csv("users.csv", users)


# Categories
categories = [
    {"category_id": 1, "category_name": "Text Generation"},
    {"category_id": 2, "category_name": "Image Processing"},
    {"category_id": 3, "category_name": "Productivity Tools"},
    {"category_id": 4, "category_name": "Data Analytics"},
    {"category_id": 5, "category_name": "Translation"},
    {"category_id": 6, "category_name": "Conversational AI"},
]
categories[0]["category_name"] = ""

write_csv("categories.csv", categories)


seller_ids = [u["user_id"] for u in users if u["role"] == "seller"]
buyer_ids = [u["user_id"] for u in users if u["role"] == "buyer"]


# Products
products = []
for i in range(1, NUM_PRODUCTS + 1):
    products.append(
        {
            "product_id": i,
            "product_name": fake.company() + " AI",
            "description": maybe_null(fake.sentence(nb_words=10), 0.15),
            "product_type": random.choice(["web_app", "api_service"]),
            "price": round(random.uniform(10, 200), 2),
            "seller_id": random.choice(seller_ids),
            "category_id": random.randint(1, len(categories)),
            "external_url": maybe_null(fake.url(), 0.15),
            "created_at": fake.date_time_this_year().isoformat(),
            "status": maybe_null(random.choice(["active", "draft", "retired"]), 0.1),
        }
    )

write_csv("products.csv", products)


# Subscriptions
subscriptions = []
active_pairs = set()

for i in range(1, NUM_SUBSCRIPTIONS + 1):
    while True:
        buyer_id = random.choice(buyer_ids)
        product_id = random.choice(products)["product_id"]
        pair = (buyer_id, product_id)

        if pair not in active_pairs:
            active_pairs.add(pair)
            break

    is_canceled = random.random() < 0.25
    status = "canceled" if is_canceled else "active"
    end_date = fake.date_this_year().isoformat() if is_canceled else ""

    subscriptions.append(
        {
            "subscription_id": i,
            "buyer_id": buyer_id,
            "product_id": product_id,
            "start_date": fake.date_this_year().isoformat(),
            "end_date": end_date,
            "status": maybe_null(status, 0.05),
        }
    )

write_csv("subscriptions.csv", subscriptions)

subscription_lookup = {s["subscription_id"]: s for s in subscriptions}
product_lookup = {p["product_id"]: p for p in products}


# Payments
payments = []
for i in range(1, NUM_PAYMENTS + 1):
    sub = random.choice(subscriptions)
    product = product_lookup[sub["product_id"]]
    amount = float(product["price"])

    payments.append(
        {
            "payment_id": i,
            "subscription_id": sub["subscription_id"],
            "payment_date": maybe_null(fake.date_this_year().isoformat(), 0.06),
            "amount": round(amount, 2),
            "commission": round(amount * 0.20, 2),
            "seller_earning": round(amount * 0.80, 2),
        }
    )

write_csv("payments.csv", payments)


# Tags
tags = [
    {"tag_id": 1, "tag_name": "presentation"},
    {"tag_id": 2, "tag_name": "translation"},
    {"tag_id": 3, "tag_name": "chatbot"},
    {"tag_id": 4, "tag_name": "automation"},
    {"tag_id": 5, "tag_name": "analytics"},
    {"tag_id": 6, "tag_name": "image-generation"},
]
tags[0]["tag_name"] = ""

write_csv("tags.csv", tags)


# Product_Tags
product_tags = []
for product in products:
    assigned_tags = random.sample(tags, random.randint(1, 3))
    for tag in assigned_tags:
        product_tags.append({"product_id": product["product_id"], "tag_id": tag["tag_id"]})

write_csv("product_tags.csv", product_tags)


# Reviews
reviews = []
review_id = 1
for sub in subscriptions:
    if random.random() < 0.6:
        reviews.append(
            {
                "review_id": review_id,
                "product_id": sub["product_id"],
                "buyer_id": sub["buyer_id"],
                "rating": random.randint(1, 5),
                "comment": maybe_null(fake.sentence(nb_words=10), 0.2),
                "review_date": maybe_null(fake.date_this_year().isoformat(), 0.05),
            }
        )
        review_id += 1

if not reviews:
    reviews.append(
        {
            "review_id": 1,
            "product_id": subscriptions[0]["product_id"],
            "buyer_id": subscriptions[0]["buyer_id"],
            "rating": 5,
            "comment": "",
            "review_date": fake.date_this_year().isoformat(),
        }
    )

write_csv("reviews.csv", reviews)


# Seller Payouts
seller_earnings = {}
for payment in payments:
    sub = subscription_lookup[payment["subscription_id"]]
    product = product_lookup[sub["product_id"]]
    seller_id = product["seller_id"]
    seller_earnings.setdefault(seller_id, 0)
    seller_earnings[seller_id] += payment["seller_earning"]

payouts = []
payout_id = 1
for seller_id, total in seller_earnings.items():
    payouts.append(
        {
            "payout_id": payout_id,
            "seller_id": seller_id,
            "payout_date": fake.date_this_year().isoformat(),
            "total_amount": round(total, 2),
            "payout_status": maybe_null(random.choice(["processed", "pending"]), 0.12),
        }
    )
    payout_id += 1

write_csv("seller_payouts.csv", payouts)