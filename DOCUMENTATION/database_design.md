# SME Working Capital & Payment Risk Analytics

## 1. Project Overview

**Project Type:** Independent, synthetic SME financial analytics portfolio project.

This project demonstrates an end-to-end data analytics workflow for analyzing financial operations in a simulated Small and Medium Enterprise (SME).

The solution uses Python for synthetic data generation and validation, MySQL for relational data storage and SQL analysis, and Power BI for interactive dashboards.

All data is simulated and does not represent any actual company.

## 2. Business Objective

The project aims to analyze:

- Customer payment behavior and credit exposure
- Outstanding accounts receivable
- Invoice aging and overdue payments
- Customer payment risk
- Collections prioritization
- Cash-flow outlook over 7, 30, and 60 days
- Sales performance and working capital drivers
- Vendor expenses and payment obligations

The objective is to support better financial visibility and data-driven working capital decisions.

## 3. Technology Stack

| Technology | Purpose |
|---|---|
| Python | Synthetic data generation, processing, and validation |
| MySQL | Relational database management, SQL queries, and analytical views |
| Power BI | Interactive dashboards, DAX measures, and KPI visualization |

## 4. Database Overview

**Database Name:** `sme_working_capital`

The analytical database is organized around five core datasets:

1. `customers` — Customer profiles, industries, locations, credit limits, and payment terms.
2. `invoices` — Customer invoices, invoice dates, due dates, and invoice amounts.
3. `payments` — Full and partial payments associated with invoices.
4. `sales` — Product-level sales transactions and revenue.
5. `expenses_payables` — Vendor expenses, payment obligations, and settlement information.

The project also includes supporting analytical SQL queries and views.

## 5. Database Relationships

The intended relational structure is:

- `customers.customer_id` → `invoices.customer_id` (one-to-many)
- `invoices.invoice_id` → `payments.invoice_id` (one-to-many)
- `invoices.invoice_id` → `sales.invoice_id` (one-to-many)

The `expenses_payables` dataset represents a separate vendor obligation ledger.

These relationships support customer-level receivables analysis, payment tracking, sales reporting, and working capital monitoring.

## 6. Dataset Schema

The following describes the documented analytical schema. Final column definitions and SQL constraints should be verified against the MySQL database before publication.

### 6.1 customers

| Column | Documented Data Type | Description |
|---|---|---|
| customer_id | INT | Customer identifier; primary key |
| customer_name | VARCHAR(100) | Customer name |
| industry | VARCHAR(50) | Customer industry |
| city | VARCHAR(50) | Customer location |
| registration_date | DATE | Registration date |
| credit_limit | DECIMAL(12,2) | Customer credit limit |
| payment_terms_days | INT | Agreed payment period |

### 6.2 invoices

| Column | Documented Data Type | Description |
|---|---|---|
| invoice_id | INT | Invoice identifier; primary key |
| customer_id | INT | Reference to customers |
| invoice_date | DATE | Invoice issue date |
| due_date | DATE | Payment due date |
| invoice_amount | DECIMAL(12,2) | Invoice amount |
| invoice_status | VARCHAR(20) | Payment status derived for a reporting date |

### 6.3 payments

| Column | Documented Data Type | Description |
|---|---|---|
| payment_id | INT | Payment identifier; primary key |
| invoice_id | INT | Reference to invoices |
| payment_date | DATE | Date of payment |
| amount_paid | DECIMAL(12,2) | Amount collected |
| payment_method | VARCHAR(30) | Payment method |

### 6.4 sales

| Column | Documented Data Type | Description |
|---|---|---|
| sale_id | INT | Sales transaction identifier; primary key |
| invoice_id | INT | Reference to invoices |
| product_id | INT | Product identifier |
| product_category | VARCHAR(50) | Product category |
| quantity | INT | Units sold |
| unit_price | DECIMAL(12,2) | Unit selling price |
| sales_amount | DECIMAL(12,2) | Sales line amount |

### 6.5 expenses_payables

| Column | Documented Data Type | Description |
|---|---|---|
| expense_id | INT | Expense identifier; primary key |
| vendor_name | VARCHAR(100) | Vendor name |
| expense_category | VARCHAR(50) | Expense classification |
| expense_date | DATE | Expense date |
| amount | DECIMAL(12,2) | Expense amount |
| due_date | DATE | Payment due date |
| payment_date | DATE | Settlement date, nullable |
| payment_status | VARCHAR(20) | Payment status for a reporting date |

## 7. Data Integrity and Validation

The project defines the following data integrity requirements:

1. Primary keys must be unique and non-null.
2. Every invoice must reference an existing customer.
3. Every payment must reference an existing invoice.
4. Every sales record must reference an existing invoice.
5. Invoice amounts should reconcile with associated sales line totals.
6. Cumulative payments should not exceed the corresponding invoice amounts.
7. Invoice due dates must not precede invoice issue dates.
8. Payment dates must not precede their associated invoice dates.
9. Expense due dates must not precede expense dates.
10. Financial statuses and outstanding balances should use a consistent reporting date.

Python validation scripts and SQL validation queries are included in the project structure.

The extent to which each rule has been verified should be confirmed from the executed validation results.

## 8. Implemented Analytics

### Accounts Receivable Analysis

Analyzes outstanding invoices, overdue receivables, payment collections, and aging patterns.

### Customer Payment Risk Analysis

Uses explainable, rule-based payment risk classification to identify customers requiring collection attention.

Risk classifications are analytical indicators based on simulated financial behavior, not predictions validated against real-world defaults.

### Cash Flow Forecast and Liquidity Analysis

Presents company-wide cash-flow outlooks for 7-day, 30-day, and 60-day periods.

The forecast is an analytical scenario based on the project's simulated data and assumptions, rather than a validated production forecasting model.

### Sales and Working Capital Analysis

Analyzes sales revenue, customer collections, and expense categories to understand financial performance and working capital drivers.

## 9. Power BI Dashboard Structure

The final Power BI report contains five interactive pages:

1. **Executive Overview** — High-level financial KPIs and business performance.
2. **Receivables & Aging Analysis** — Outstanding balances, overdue invoices, and aging distribution.
3. **Customer Payment Risk Analysis** — Risk segmentation, exposure, and customer payment behavior.
4. **Cash Flow Forecast & Liquidity Analysis** — Company-wide 7/30/60-day cash-flow outlook.
5. **Sales & Working Capital Drivers** — Sales performance, collections, and expense analysis.

**Dashboard interpretation notes:**

- Customer and industry filters apply where the underlying data model supports those relationships.
- Cash-flow outlook figures are company-wide and are not represented as customer- or industry-specific forecasts.
- Expense-category figures are company-wide and should not be interpreted as industry-specific expenses.

## 10. Data Policy and Limitations

- All customer, invoice, payment, sales, and expense records are synthetic.
- The project is independent and is not affiliated with a real company.
- Simulated financial figures should not be presented as actual business results.
- Customer risk scores are rule-based analytical classifications.
- Cash-flow outlooks are illustrative and depend on the assumptions used.
- SQL views and DAX measures should be interpreted according to their filtering and aggregation logic.
- Final database constraints and validation outcomes should be checked against the saved SQL scripts and database.

## 11. Project Deliverables

- Synthetic financial datasets in CSV format
- Python data generation and validation scripts
- MySQL analytical queries and views
- Power BI report with five dashboard pages
- Dashboard screenshots
- Database design documentation

## 12. Conclusion

The SME Working Capital & Payment Risk Analytics project demonstrates how Python, MySQL, and Power BI can be combined to develop a financial analytics solution.

It showcases relational data modeling, SQL analysis, KPI development, customer payment risk segmentation, cash-flow analysis, and interactive business intelligence reporting using a simulated SME environment.

The project is intended as a portfolio demonstration of practical Data Analyst skills.