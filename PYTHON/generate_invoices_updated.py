from pathlib import Path
from datetime import date, timedelta
import numpy as np
import pandas as pd

PROJECT_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_DIR / 'DATA'
customers = pd.read_csv(DATA_DIR / 'customers.csv')

rng = np.random.default_rng(123)
NUM_INVOICES = 100_000
REPORTING_DATE = date(2026, 9, 30)
EARLIEST_DATE = date(2024, 1, 1)

# Synthetic assumptions: a recent-heavy invoice mix, not a claim about actual SMEs.
# Invoice ages: 0-30 (30%), 31-90 (35%), 91-180 (20%), 181-365 (10%), 366-1003 (5%).
age_bands = [(0, 30), (31, 90), (91, 180), (181, 365),
             (366, (REPORTING_DATE - EARLIEST_DATE).days)]
weights = [0.30, 0.35, 0.20, 0.10, 0.05]

rows = []
for invoice_id in range(1, NUM_INVOICES + 1):
    customer = customers.iloc[int(rng.integers(0, len(customers)))]
    registered = date.fromisoformat(str(customer['registration_date']))
    earliest_allowed = max(registered, EARLIEST_DATE)
    if earliest_allowed > REPORTING_DATE:
        raise ValueError(f"Customer {customer['customer_id']} registered after reporting date")

    max_age = (REPORTING_DATE - earliest_allowed).days
    eligible = [(lo, min(hi, max_age), weight)
                for (lo, hi), weight in zip(age_bands, weights) if lo <= max_age]
    normalized = np.array([weight for _, _, weight in eligible], dtype=float)
    normalized /= normalized.sum()
    chosen = eligible[int(rng.choice(len(eligible), p=normalized))]
    age = int(rng.integers(chosen[0], chosen[1] + 1))
    invoice_date = REPORTING_DATE - timedelta(days=age)
    due_date = invoice_date + timedelta(days=int(customer['payment_terms_days']))
    amount = int(rng.integers(5000, 150001))

    rows.append({
        'invoice_id': invoice_id,
        'customer_id': int(customer['customer_id']),
        'invoice_date': invoice_date.isoformat(),
        'due_date': due_date.isoformat(),
        'invoice_amount': amount,
        'invoice_status': 'Pending',
    })

df = pd.DataFrame(rows)
assert len(df) == NUM_INVOICES and df['invoice_id'].is_unique
assert df['customer_id'].isin(customers['customer_id']).all()
assert (pd.to_datetime(df['due_date']) >= pd.to_datetime(df['invoice_date'])).all()
assert (pd.to_datetime(df['invoice_date']) <= pd.Timestamp(REPORTING_DATE)).all()

output = DATA_DIR / 'invoices.csv'
df.to_csv(output, index=False)
print(f'Generated {len(df):,} synthetic invoices: {output}')
print('Invoice age distribution (days):')
print(pd.cut((pd.Timestamp(REPORTING_DATE) - pd.to_datetime(df['invoice_date'])).dt.days,
             bins=[-1, 30, 90, 180, 365, 10000],
             labels=['0-30', '31-90', '91-180', '181-365', '366+']).value_counts().sort_index())
