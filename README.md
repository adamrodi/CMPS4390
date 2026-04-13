# CMPS4390 Database Project - Team Mango

Semester repository for the AI Marketplace database project in CMPS4390.

## Project Context

This project models an online marketplace where sellers publish AI products and buyers subscribe to them.
The platform handles listing, subscriptions, billing, commission split, and payout aggregation.

Core proposal entities currently tracked in this repo:

- users
- categories
- products
- tags
- product_tags
- subscriptions
- payments
- reviews
- seller_payouts

## Repository Layout

```text
.
├── CLAUDE.md
├── README.md
├── requirements.txt
├── Generate_Data/
│   ├── generate_csv.py
│   ├── verify_integrity.py
│   └── Readme.md
├── Docs/
│   └── PA2.pptx
├── sql/
│   └── Queries.sql
└── .gitignore
```

## Fast Start

1. Generate synthetic data in CSV format:

```bash
cd Generate_Data
python3 -m venv .venv
source .venv/bin/activate
pip install Faker
python generate_csv.py
python verify_integrity.py
```

2. Run SQL deliverables against SQL Server:

- `sql/Queries.sql` contains all DDL (QD1–5) and DML (QM1–11) for the assignment.

3. Build submission artifacts:

- Use `Docs/PA2.pptx` without changing order or slide format.
- Fill every required query from `sql/Queries.sql`.
- Include query output snapshots as required by the template.

## Required Final Deliverables (Course Rubric)

- Presentation using the provided template file
- Excel workbook with one table per sheet and first row as attribute names
- SQL query file
- Database backup as `DB_<TEAM NAME>.bak`
- Participation questionnaire

## Notes

- The data generator and verifier are proposal-aligned and enforce relational consistency.
- Generated CSV files in `Generate_Data` are treated as disposable build artifacts.
