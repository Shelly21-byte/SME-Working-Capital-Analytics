
from pathlib import Path
from datetime import date, timedelta
import numpy as np
import pandas as pd

# Project configuration
DATA_DIR = Path(__file__).resolve().parent.parent / "DATA"
REPORTING_DATE = date(2026, 9, 30)
START_DATE = date(2024, 1, 1)

NUM_EXPENSES = 30000
rng = np.random.default_rng(321)

categories = [
    "Raw Materials", "Logistics", "Rent",
    "Utilities", "Maintenance", "Marketing",
    "Software", "Office Supplies"
]

vendors = [
    "Apex Suppliers", "Metro Logistics",
    "Prime Materials", "Nova Services",
    "Bright Solutions", "Royal Traders",
    "Green Enterprises", "Sunrise Distributors",
    "Urban Supplies", "Reliable Industries"
]

expenses = []

date_span = (REPORTING_DATE - START_DATE).days

for expense_id in range(1, NUM_EXPENSES + 1):

    expense_date = START_DATE + timedelta(
        days=int(rng.integers(0, date_span + 1))
    )

    payment_terms = int(rng.choice([15, 30, 45, 60]))
    due_date = expense_date + timedelta(days=payment_terms)

    amount = int(rng.integers(2000, 200001))

    # Simulate whether an expense has been paid
    is_paid = bool(rng.random() < 0.72)

    payment_date = None

    if is_paid:
        delay = int(rng.integers(0, payment_terms + 31))
        candidate_date = expense_date + timedelta(days=delay)

        if candidate_date <= REPORTING_DATE:
            payment_date = candidate_date

    # Determine status as of reporting date
    if payment_date is not None:
        payment_status = "Paid"
    elif due_date < REPORTING_DATE:
        payment_status = "Overdue"
    else:
        payment_status = "Pending"

    expenses.append({
        "expense_id": expense_id,
        "vendor_name": str(rng.choice(vendors)),
        "expense_category": str(rng.choice(categories)),
        "expense_date": expense_date.isoformat(),
        "amount": amount,
        "due_date": due_date.isoformat(),
        "payment_date": (
            payment_date.isoformat()
            if payment_date is not None else None
        ),
        "payment_status": payment_status
    })

df = pd.DataFrame(expenses)

# Data validation
assert len(df) == NUM_EXPENSES
assert df["expense_id"].is_unique
assert (df["amount"] > 0).all()

expense_dates = pd.to_datetime(df["expense_date"])
due_dates = pd.to_datetime(df["due_date"])
payment_dates = pd.to_datetime(df["payment_date"])

assert (due_dates >= expense_dates).all()
assert (
    (payment_dates.isna()) |
    (payment_dates >= expense_dates)
).all()
assert (
    (payment_dates.isna()) |
    (payment_dates <= pd.Timestamp(REPORTING_DATE))
).all()

assert (
    (df["payment_status"] == "Paid")
    == payment_dates.notna()
).all()

# Save file
output_file = DATA_DIR / "expenses_payables.csv"
df.to_csv(output_file, index=False)

print("Expenses dataset generated successfully!")
print(f"Total expense records: {len(df):,}")
print(f"Total columns: {len(df.columns)}")
print(f"Saved to: {output_file}")

print("\nPayment status distribution:")
print(df["payment_status"].value_counts())

print("\nFirst 5 expense records:")
print(df.head().to_string(index=False))
