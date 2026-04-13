# AI Marketplace Synthetic Data Generator

This folder contains the reproducible data pipeline for the CMPS4390 AI Marketplace proposal.

## What It Generates

The generator produces proposal-aligned CSV tables:

- users.csv
- categories.csv
- products.csv
- subscriptions.csv
- payments.csv
- reviews.csv
- seller_payouts.csv
- tags.csv
- product_tags.csv

The files are overwritten each run.

## Proposal Alignment

The generated schema supports:

- Buyer and seller user roles
- Product listings tied to sellers and categories
- Subscription billing and 20% platform commission logic
- Many-to-many product tags
- Reviews restricted to valid buyer-product subscription pairs
- Seller payout aggregation from payment earnings

## Setup

1. Create a virtual environment:

```bash
python3 -m venv .venv
```

2. Activate it:

```bash
source .venv/bin/activate
```

3. Install dependency:

```bash
pip install Faker
```

## Generate Data

```bash
python generate_csv.py
```

## Verify Integrity

```bash
python verify_integrity.py
```

The verifier checks:

- Role and foreign key validity
- Payment and commission math correctness
- Seller payout rollup correctness
- Review/subscription consistency
- Duplicate prevention in product_tags
- NULL-presence counts per table for rubric support

## Notes About NULL Requirement

The rubric says each table should include NULL values.

- This generator intentionally includes NULL-like blanks in most tables.
- `product_tags` is currently a pure junction table with only key columns, so NULLs are structurally awkward.
- If NULLs in every table is required, add one optional non-key attribute to `product_tags`.
