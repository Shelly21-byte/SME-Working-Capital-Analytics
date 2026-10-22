
from pathlib import Path
from datetime import date, timedelta
import numpy as np
import pandas as pd

# Reproducible synthetic data
rng = np.random.default_rng(42)
NUM_CUSTOMERS = 5000

# Project DATA folder
DATA_DIR = Path(__file__).resolve().parent.parent / "DATA"
DATA_DIR.mkdir(parents=True, exist_ok=True)

industries = [
    "Retail", "Manufacturing", "Wholesale",
    "Healthcare", "Technology", "Logistics",
    "Construction", "Food & Beverage"
]

cities = [
    "Mumbai", "Delhi", "Bengaluru", "Jaipur",
    "Pune", "Hyderabad", "Kota", "Ahmedabad",
    "Chennai", "Indore"
]

business_prefixes = [
    "Apex", "Bright", "Prime", "Sunrise",
    "Green", "Metro", "Royal", "Nova"
]

business_suffixes = [
    "Traders", "Enterprises", "Solutions",
    "Industries", "Supplies", "Distributors"
]

start_date = date(2022, 1, 1)
end_date = date(2025, 12, 31)
date_range = (end_date - start_date).days

customers = []

for customer_id in range(1, NUM_CUSTOMERS + 1):
    prefix = rng.choice(business_prefixes)
    suffix = rng.choice(business_suffixes)

    # Unique fictional business name
    customer_name = f"{prefix} {suffix} {customer_id:05d}"

    registration_date = start_date + timedelta(
        days=int(rng.integers(0, date_range + 1))
    )

    customers.append({
        "customer_id": customer_id,
        "customer_name": customer_name,
        "industry": rng.choice(industries),
        "city": rng.choice(cities),
        "registration_date": registration_date.isoformat(),
        "credit_limit": int(rng.choice([
            50000, 100000, 200000, 500000, 1000000
        ])),
        "payment_terms_days": int(rng.choice([15, 30, 45, 60]))
    })

df = pd.DataFrame(customers)

# Validate the dataset
assert len(df) == NUM_CUSTOMERS
assert df["customer_id"].is_unique
assert df.notna().all().all()
assert (df["credit_limit"] > 0).all()

output_file = DATA_DIR / "customers.csv"
df.to_csv(output_file, index=False)

print("Customer dataset generated successfully!")
print(f"Total customers: {len(df):,}")
print(f"Total columns: {len(df.columns)}")
print(f"Saved to: {output_file}")
print("\nFirst 5 customer records:")
print(df.head().to_string(index=False))
  