
from pathlib import Path
import pandas as pd
import numpy as np

DATA_DIR = Path(__file__).resolve().parent.parent / "DATA"
REPORTING_DATE = pd.Timestamp("2026-09-30")

invoices = pd.read_csv(DATA_DIR / "invoices.csv")
payments = pd.read_csv(DATA_DIR / "payments.csv")

# Total payments per invoice
paid = payments.groupby("invoice_id")["amount_paid"].sum()

invoices["total_paid"] = (
    invoices["invoice_id"].map(paid).fillna(0).astype("int64")
)

invoices["outstanding_amount"] = (
    invoices["invoice_amount"] - invoices["total_paid"]
)

invoices["due_date"] = pd.to_datetime(invoices["due_date"])

# Calculate invoice status
conditions = [
    invoices["outstanding_amount"] == 0,
    (invoices["outstanding_amount"] > 0)
    & (invoices["due_date"] < REPORTING_DATE),
    (invoices["total_paid"] > 0)
    & (invoices["outstanding_amount"] > 0),
]

choices = ["Paid", "Overdue", "Partially Paid"]

invoices["invoice_status"] = np.select(
    conditions,
    choices,
    default="Pending"
)

# Calculate overdue days independently of invoice status
invoices["days_overdue"] = np.where(
    (invoices["outstanding_amount"] > 0)
    & (invoices["due_date"] < REPORTING_DATE),
    (REPORTING_DATE - invoices["due_date"]).dt.days,
    0
)

# Validation
assert (invoices["outstanding_amount"] >= 0).all()
assert (
    invoices["invoice_amount"].sum()
    == invoices["total_paid"].sum()
    + invoices["outstanding_amount"].sum()
)

# Save enriched dataset separately
output = DATA_DIR / "invoice_status_summary.csv"

invoices.to_csv(output, index=False)

print("Invoice status calculation completed!")
print("\nInvoice Status Distribution:")
print(invoices["invoice_status"].value_counts())

print("\nFinancial Summary:")
print(f"Total Invoiced: INR {invoices['invoice_amount'].sum():,.2f}")
print(f"Total Paid: INR {invoices['total_paid'].sum():,.2f}")
print(f"Outstanding: INR {invoices['outstanding_amount'].sum():,.2f}")

print(f"\nSaved to: {output}")
