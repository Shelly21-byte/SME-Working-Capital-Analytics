from pathlib import Path
from datetime import date, timedelta
import numpy as np
import pandas as pd

# Synthetic transactions for portfolio demonstration; not actual customer records.
DATA_DIR = Path(__file__).resolve().parent.parent / 'DATA'
REPORTING_DATE = date(2026, 9, 30)
rng = np.random.default_rng(789)

invoices = pd.read_csv(DATA_DIR / 'invoices.csv')
customers = pd.read_csv(DATA_DIR / 'customers.csv')

assert invoices['invoice_id'].is_unique
assert invoices['customer_id'].isin(customers['customer_id']).all()

# Persistent customer-level payment propensity: most reliable, some moderate, few risky.
customer_ids = customers['customer_id'].astype(int).to_numpy()
tiers = rng.choice(['reliable', 'moderate', 'risky'], size=len(customer_ids),
                   p=[0.60, 0.30, 0.10])
tier_by_customer = dict(zip(customer_ids, tiers))
methods = ['UPI', 'Bank Transfer', 'NEFT', 'Cheque']

rows = []
payment_id = 1
for inv in invoices.itertuples(index=False):
    invoice_date = date.fromisoformat(inv.invoice_date)
    due_date = date.fromisoformat(inv.due_date)
    amount = int(inv.invoice_amount)
    customer_id = int(inv.customer_id)
    tier = tier_by_customer[customer_id]
    age_since_due = (REPORTING_DATE - due_date).days

    # Payment status depends on BOTH customer behavior and how long invoice has existed.
    # For older invoices, reliable customers are very likely to have paid in full.
    if age_since_due < 0:
        probabilities = {
            'reliable': [0.35, 0.20, 0.45],
            'moderate': [0.20, 0.20, 0.60],
            'risky': [0.08, 0.12, 0.80],
        }
    elif age_since_due <= 30:
        probabilities = {
            'reliable': [0.82, 0.13, 0.05],
            'moderate': [0.60, 0.25, 0.15],
            'risky': [0.32, 0.30, 0.38],
        }
    elif age_since_due <= 90:
        probabilities = {
            'reliable': [0.94, 0.05, 0.01],
            'moderate': [0.77, 0.16, 0.07],
            'risky': [0.45, 0.30, 0.25],
        }
    else:
        probabilities = {
            'reliable': [0.98, 0.015, 0.005],
            'moderate': [0.86, 0.11, 0.03],
            'risky': [0.52, 0.30, 0.18],
        }

    behavior = str(rng.choice(['full', 'partial', 'unpaid'], p=probabilities[tier]))
    if behavior == 'unpaid':
        continue
    total_paid = amount if behavior == 'full' else max(1, int(amount * rng.uniform(0.25, 0.85)))

    # For full/partial payments, record 1-3 installments within valid dates.
    # Some payments occur before due date, some after; none occur in the future.
    last_allowed = REPORTING_DATE
    if last_allowed < invoice_date:
        raise ValueError('Invoice date exceeds reporting date')
    max_offset = (last_allowed - invoice_date).days
    num_installments = min(int(rng.choice([1, 2, 3], p=[0.55, 0.32, 0.13])), max_offset + 1)

    # Prefer payment dates around the due date, bounded by invoice date and as-of date.
    center = (due_date - invoice_date).days + int(rng.normal(loc=0 if tier == 'reliable' else 12 if tier == 'moderate' else 28,
                                                             scale=12 if tier == 'reliable' else 22))
    offsets = []
    for _ in range(num_installments):
        offset = int(np.clip(center + rng.normal(0, 10), 0, max_offset))
        offsets.append(offset)
    offsets.sort()

    if num_installments == 1:
        amounts = [total_paid]
    else:
        proportions = rng.dirichlet(np.ones(num_installments))
        amounts = [int(x) for x in np.floor(proportions * total_paid)]
        amounts[-1] += total_paid - sum(amounts)
        # Rare zero-value installment: fold it into the last installment.
        nonzero = [(off, paid) for off, paid in zip(offsets, amounts) if paid > 0]
        offsets = [off for off, _ in nonzero]
        amounts = [paid for _, paid in nonzero]

    for offset, paid_amount in zip(offsets, amounts):
        rows.append({
            'payment_id': payment_id,
            'invoice_id': int(inv.invoice_id),
            'payment_date': (invoice_date + timedelta(days=offset)).isoformat(),
            'amount_paid': int(paid_amount),
            'payment_method': str(rng.choice(methods)),
        })
        payment_id += 1

payments = pd.DataFrame(rows)
assert payments['payment_id'].is_unique
assert payments['invoice_id'].isin(invoices['invoice_id']).all()
assert (payments['amount_paid'] > 0).all()
paid = payments.groupby('invoice_id')['amount_paid'].sum()
amounts = invoices.set_index('invoice_id')['invoice_amount']
assert (paid.reindex(amounts.index, fill_value=0) <= amounts).all()
check = payments.merge(invoices[['invoice_id', 'invoice_date']], on='invoice_id')
assert (pd.to_datetime(check['payment_date']) >= pd.to_datetime(check['invoice_date'])).all()
assert (pd.to_datetime(payments['payment_date']) <= pd.Timestamp(REPORTING_DATE)).all()

output = DATA_DIR / 'payments.csv'
payments.to_csv(output, index=False)
print(f'Generated {len(payments):,} synthetic payment records: {output}')
print(f'Invoices with payments: {payments.invoice_id.nunique():,} / {len(invoices):,}')
