
from pathlib import Path
import pandas as pd

DATA_DIR = Path(__file__).resolve().parent.parent / "DATA"
REPORTING_DATE = pd.Timestamp("2026-09-30")

# Load all five datasets
customers = pd.read_csv(DATA_DIR / "customers.csv")
invoices = pd.read_csv(DATA_DIR / "invoices.csv")
sales = pd.read_csv(DATA_DIR / "sales.csv")
payments = pd.read_csv(DATA_DIR / "payments.csv")
expenses = pd.read_csv(DATA_DIR / "expenses_payables.csv")

print("SME DATA QUALITY VALIDATION")
print("=" * 45)

datasets = {
    "Customers": (customers, "customer_id"),
    "Invoices": (invoices, "invoice_id"),
    "Sales": (sales, "sale_id"),
    "Payments": (payments, "payment_id"),
    "Expenses": (expenses, "expense_id")
}

for name, (df, primary_key) in datasets.items():
    assert df[primary_key].notna().all()
    assert df[primary_key].is_unique

    print(
        f"{name}: {len(df):,} rows | "
        f"Missing cells: {df.isna().sum().sum():,}"
    )

# Validate relationships
assert invoices["customer_id"].isin(
    customers["customer_id"]
).all()

assert sales["invoice_id"].isin(
    invoices["invoice_id"]
).all()

assert payments["invoice_id"].isin(
    invoices["invoice_id"]
).all()

print("PASS: All foreign key relationships")

# Validate invoice-sales reconciliation
sales_totals = sales.groupby("invoice_id")[
    "sales_amount"
].sum()

invoice_totals = invoices.set_index(
    "invoice_id"
)["invoice_amount"]

assert sales_totals.reindex(
    invoice_totals.index, fill_value=0
).equals(invoice_totals)

print("PASS: All invoice-sales totals reconciled")

# Validate payments
paid_totals = payments.groupby("invoice_id")[
    "amount_paid"
].sum()

paid = paid_totals.reindex(
    invoice_totals.index, fill_value=0
)

assert (paid <= invoice_totals).all()
assert (paid >= 0).all()

print("PASS: Payment amounts are within invoice limits")

# Validate payment dates
payment_check = payments.merge(
    invoices[["invoice_id", "invoice_date"]],
    on="invoice_id",
    how="left"
)

assert (
    pd.to_datetime(payment_check["payment_date"])
    >= pd.to_datetime(payment_check["invoice_date"])
).all()

assert (
    pd.to_datetime(payments["payment_date"])
    <= REPORTING_DATE
).all()

print("PASS: Payment dates are valid")

# Validate expenses
expense_date = pd.to_datetime(expenses["expense_date"])
expense_due = pd.to_datetime(expenses["due_date"])
expense_paid = pd.to_datetime(expenses["payment_date"])

assert (expense_due >= expense_date).all()

assert (
    expense_paid.isna() | (expense_paid >= expense_date)
).all()

assert (
    expense_paid.isna() | (expense_paid <= REPORTING_DATE)
).all()

print("PASS: Expense dates are valid")

# Financial summary
outstanding = invoice_totals - paid

print("\nFINANCIAL SUMMARY")
print("=" * 45)
print(f"Total invoiced: INR {invoice_totals.sum():,.2f}")
print(f"Total collected: INR {paid.sum():,.2f}")
print(f"Outstanding receivables: INR {outstanding.sum():,.2f}")

assert (outstanding >= 0).all()

print("\nALL DATA VALIDATION CHECKS PASSED!")
