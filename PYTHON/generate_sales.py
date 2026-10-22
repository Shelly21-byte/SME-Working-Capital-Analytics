
from pathlib import Path
import numpy as np
import pandas as pd

DATA_DIR = Path(__file__).resolve().parent.parent / "DATA"

invoices = pd.read_csv(DATA_DIR / "invoices.csv")

rng = np.random.default_rng(456)

categories = [
    "Electronics", "Office Supplies", "Packaging",
    "Industrial Equipment", "Furniture", "Accessories"
]

sales = []
sale_id = 1

for invoice in invoices.itertuples(index=False):
    invoice_id = int(invoice.invoice_id)
    total_amount = int(invoice.invoice_amount)

    # Each invoice has 1 to 3 sales lines
    num_lines = int(rng.choice(
        [1, 2, 3], p=[0.25, 0.50, 0.25]
    ))

    # Split invoice amount into positive integer amounts
    if num_lines == 1:
        amounts = [total_amount]
    else:
        cuts = sorted(
            rng.choice(
                np.arange(1, total_amount),
                size=num_lines - 1,
                replace=False
            ).tolist()
        )
        amounts = np.diff(
            [0] + cuts + [total_amount]
        ).tolist()

    for amount in amounts:
        category = str(rng.choice(categories))
        product_id = int(rng.integers(1001, 1101))

        # Quantity 1 keeps monetary totals exact
        quantity = 1
        unit_price = int(amount)

        sales.append({
            "sale_id": sale_id,
            "invoice_id": invoice_id,
            "product_id": product_id,
            "product_category": category,
            "quantity": quantity,
            "unit_price": unit_price,
            "sales_amount": int(amount)
        })

        sale_id += 1

df = pd.DataFrame(sales)

# Validate relationships and financial reconciliation
assert df["sale_id"].is_unique
assert df["invoice_id"].isin(
    invoices["invoice_id"]
).all()

assert (
    df["sales_amount"]
    == df["quantity"] * df["unit_price"]
).all()

totals = df.groupby("invoice_id")["sales_amount"].sum()

expected = invoices.set_index("invoice_id")["invoice_amount"]

assert totals.reindex(expected.index).equals(expected)

output_file = DATA_DIR / "sales.csv"
df.to_csv(output_file, index=False)

print("Sales dataset generated successfully!")
print(f"Total sales records: {len(df):,}")
print(f"Total invoices reconciled: {len(totals):,}")
print(f"Saved to: {output_file}")
print("\nFirst 5 sales records:")
print(df.head().to_string(index=False))
