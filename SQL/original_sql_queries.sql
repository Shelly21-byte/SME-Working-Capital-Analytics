
CREATE DATABASE IF NOT EXISTS sme_working_capital;
USE sme_working_capital;

-- 1. CUSTOMERS
CREATE TABLE IF NOT EXISTS customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(150),
    industry VARCHAR(100),
    city VARCHAR(100),
    registration_date DATE,
    credit_limit DECIMAL(15,2),
    payment_terms_days INT
);

-- 2. INVOICES
CREATE TABLE IF NOT EXISTS invoices (
    invoice_id INT PRIMARY KEY,
    customer_id INT NOT NULL,
    invoice_date DATE,
    due_date DATE,
    invoice_amount DECIMAL(15,2),
    invoice_status VARCHAR(30),
    FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
);

-- 3. SALES
CREATE TABLE IF NOT EXISTS sales (
    sale_id INT PRIMARY KEY,
    invoice_id INT NOT NULL,
    product_id INT,
    product_category VARCHAR(100),
    quantity INT,
    unit_price DECIMAL(15,2),
    sales_amount DECIMAL(15,2),
    FOREIGN KEY (invoice_id)
        REFERENCES invoices(invoice_id)
);

-- 4. PAYMENTS
CREATE TABLE IF NOT EXISTS payments (
    payment_id INT PRIMARY KEY,
    invoice_id INT NOT NULL,
    payment_date DATE,
    amount_paid DECIMAL(15,2),
    payment_method VARCHAR(50),
    FOREIGN KEY (invoice_id)
        REFERENCES invoices(invoice_id)
);

-- 5. EXPENSES & PAYABLES
CREATE TABLE IF NOT EXISTS expenses_payables (
    expense_id INT PRIMARY KEY,
    vendor_name VARCHAR(150),
    expense_category VARCHAR(100),
    expense_date DATE,
    amount DECIMAL(15,2),
    due_date DATE,
    payment_date DATE,
    payment_status VARCHAR(30)
);

-- VERIFY TABLES
SHOW TABLES;

USE sme_working_capital;
SELECT COUNT(*) AS total_customers
FROM customers;

USE sme_working_capital;
SELECT COUNT(*) AS total_invoices
FROM invoices;

SELECT COUNT(*) AS total_sales
FROM sme_working_capital.sales;

USE sme_working_capital;
SELECT COUNT(*) AS total_payments
FROM payments;

SELECT COUNT(*) AS total_payments
FROM sme_working_capital.payments;

SHOW COLUMNS
FROM sme_working_capital.expenses_payables;

SELECT COUNT(*) AS total_expenses
FROM sme_working_capital.expenses_payables;

-- DELETE FROM sme_working_capital.expenses_payables;

-- TRUNCATE TABLE sme_working_capital.expenses_payables;

SELECT COUNT(*) AS total_expenses
FROM sme_working_capital.expenses_payables;

SELECT 'customers' AS table_name, COUNT(*) AS total_rows
FROM sme_working_capital.customers
UNION ALL
SELECT 'invoices', COUNT(*)
FROM sme_working_capital.invoices
UNION ALL
SELECT 'payments', COUNT(*)
FROM sme_working_capital.payments
UNION ALL
SELECT 'sales', COUNT(*)
FROM sme_working_capital.sales
UNION ALL
SELECT 'expenses_payables', COUNT(*)
FROM sme_working_capital.expenses_payables;

TRUNCATE TABLE sme_working_capital.expenses_payables;

SELECT COUNT(*) AS total_expenses
FROM sme_working_capital.expenses_payables;

SHOW GLOBAL VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = ON;

LOAD DATA LOCAL INFILE 'C:/path/to/SME-Working-Capital-Analytics/DATA/expenses_payables_cleaned.csv'
INTO TABLE sme_working_capital.expenses_payables
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(expense_id, vendor_name, expense_category,
 expense_date, amount, due_date,
 @payment_date, payment_status)
SET payment_date = NULLIF(TRIM(TRAILING '\r' FROM @payment_date), '');

SELECT COUNT(*) AS total_expenses
FROM sme_working_capital.expenses_payables;

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT expense_id) AS unique_ids,
    SUM(expense_date IS NULL) AS missing_expense_dates,
    SUM(due_date IS NULL) AS missing_due_dates
FROM sme_working_capital.expenses_payables;

SELECT 'customers' AS table_name, COUNT(*) AS total_rows
FROM sme_working_capital.customers
UNION ALL
SELECT 'invoices', COUNT(*)
FROM sme_working_capital.invoices
UNION ALL
SELECT 'payments', COUNT(*)
FROM sme_working_capital.payments
UNION ALL
SELECT 'sales', COUNT(*)
FROM sme_working_capital.sales
UNION ALL
SELECT 'expenses_payables', COUNT(*)
FROM sme_working_capital.expenses_payables;

SELECT
    COUNT(*) AS total_payments,
    COUNT(DISTINCT payment_id) AS unique_payment_ids
FROM sme_working_capital.payments;

USE sme_working_capital;
DESCRIBE customers;
DESCRIBE invoices;
DESCRIBE payments;
DESCRIBE sales;
DESCRIBE expenses_payables;

SELECT COUNT(*) AS orphan_invoices
FROM sme_working_capital.invoices i
LEFT JOIN sme_working_capital.customers c
    ON i.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS orphan_payments
FROM sme_working_capital.payments p
LEFT JOIN sme_working_capital.invoices i
    ON p.invoice_id = i.invoice_id
WHERE i.invoice_id IS NULL;

SELECT COUNT(*) AS orphan_sales
FROM sme_working_capital.sales s
LEFT JOIN sme_working_capital.invoices i
    ON s.invoice_id = i.invoice_id
WHERE i.invoice_id IS NULL;

SELECT
    COUNT(*) AS total_payments,
    SUM(payment_date IS NULL) AS missing_payment_dates,
    SUM(amount_paid IS NULL) AS missing_amounts
FROM sme_working_capital.payments;

SELECT
    COUNT(*) AS invalid_payments
FROM sme_working_capital.payments
WHERE amount_paid <= 0;

SELECT
    COUNT(*) AS total_invoices,
    SUM(invoice_date IS NULL) AS missing_invoice_dates,
    SUM(due_date IS NULL) AS missing_due_dates,
    SUM(invoice_amount <= 0) AS invalid_amounts
FROM sme_working_capital.invoices;

SELECT COUNT(*) AS invalid_due_dates
FROM sme_working_capital.invoices
WHERE due_date < invoice_date;

SELECT COUNT(*) AS payments_before_invoice
FROM sme_working_capital.payments p
JOIN sme_working_capital.invoices i
    ON p.invoice_id = i.invoice_id
WHERE p.payment_date < i.invoice_date;

SELECT
    COUNT(*) AS overpaid_invoices
FROM sme_working_capital.invoices i
JOIN (
    SELECT
        invoice_id,
        SUM(amount_paid) AS total_paid
    FROM sme_working_capital.payments
    GROUP BY invoice_id
) p ON i.invoice_id = p.invoice_id
WHERE p.total_paid > i.invoice_amount;

SELECT
    ROUND(SUM(i.invoice_amount), 2) AS total_invoiced,
    ROUND(SUM(COALESCE(p.total_paid, 0)), 2) AS total_collected,
    ROUND(SUM(i.invoice_amount - COALESCE(p.total_paid, 0)), 2)
        AS outstanding_receivables
FROM sme_working_capital.invoices i
LEFT JOIN (
    SELECT
        invoice_id,
        SUM(amount_paid) AS total_paid
    FROM sme_working_capital.payments
    GROUP BY invoice_id
) p ON i.invoice_id = p.invoice_id;

SELECT
    ROUND(
        100 * (
            SELECT SUM(amount_paid)
            FROM sme_working_capital.payments
        ) / NULLIF((
            SELECT SUM(invoice_amount)
            FROM sme_working_capital.invoices
        ), 0),
        2
    ) AS collection_rate_pct;

SELECT
    COUNT(*) AS overdue_invoice_count,
    ROUND(SUM(outstanding_amount), 2)
        AS overdue_receivables
FROM (
    SELECT
        i.invoice_id,
        i.due_date,
        i.invoice_amount - COALESCE(
            SUM(p.amount_paid), 0
        ) AS outstanding_amount
    FROM sme_working_capital.invoices i
    LEFT JOIN sme_working_capital.payments p
        ON i.invoice_id = p.invoice_id
        AND p.payment_date <= '2026-10-21'
    WHERE i.invoice_date <= '2026-10-21'
    GROUP BY
        i.invoice_id,
        i.due_date,
        i.invoice_amount
) x
WHERE due_date < '2026-10-21'
  AND outstanding_amount > 0;
  
  SELECT
    CASE
        WHEN days_overdue BETWEEN 1 AND 30 THEN '1-30 Days'
        WHEN days_overdue BETWEEN 31 AND 60 THEN '31-60 Days'
        WHEN days_overdue BETWEEN 61 AND 90 THEN '61-90 Days'
        ELSE '90+ Days'
    END AS aging_bucket,
    COUNT(*) AS invoice_count,
    ROUND(SUM(outstanding_amount), 2)
        AS overdue_amount
FROM (
    SELECT
        i.invoice_id,
        DATEDIFF('2026-10-21', i.due_date)
            AS days_overdue,
        i.invoice_amount -
            COALESCE(SUM(p.amount_paid), 0)
            AS outstanding_amount
    FROM sme_working_capital.invoices i
    LEFT JOIN sme_working_capital.payments p
        ON i.invoice_id = p.invoice_id
        AND p.payment_date <= '2026-10-21'
    WHERE i.invoice_date <= '2026-10-21'
    GROUP BY
        i.invoice_id,
        i.due_date,
        i.invoice_amount
) x
WHERE days_overdue > 0
  AND outstanding_amount > 0
GROUP BY aging_bucket
ORDER BY
    CASE aging_bucket
        WHEN '1-30 Days' THEN 1
        WHEN '31-60 Days' THEN 2
        WHEN '61-90 Days' THEN 3
        ELSE 4
    END;
    
    SELECT
    c.customer_id,
    c.customer_name,
    ROUND(SUM(x.outstanding_amount), 2)
        AS total_outstanding
FROM sme_working_capital.customers c
JOIN (
    SELECT
        i.customer_id,
        i.invoice_id,
        i.invoice_amount -
            COALESCE(SUM(p.amount_paid), 0)
            AS outstanding_amount
    FROM sme_working_capital.invoices i
    LEFT JOIN sme_working_capital.payments p
        ON i.invoice_id = p.invoice_id
        AND p.payment_date <= '2026-10-21'
    WHERE i.invoice_date <= '2026-10-21'
    GROUP BY
        i.customer_id,
        i.invoice_id,
        i.invoice_amount
) x ON c.customer_id = x.customer_id
WHERE x.outstanding_amount > 0
GROUP BY c.customer_id, c.customer_name
ORDER BY total_outstanding DESC
LIMIT 10;

SELECT
    c.customer_id,
    c.customer_name,
    COUNT(*) AS overdue_invoice_count,
    ROUND(SUM(x.outstanding_amount), 2) AS overdue_amount
FROM sme_working_capital.customers c
JOIN (
    SELECT
        i.customer_id,
        i.invoice_id,
        i.due_date,
        i.invoice_amount - COALESCE(SUM(p.amount_paid), 0)
            AS outstanding_amount
    FROM sme_working_capital.invoices i
    LEFT JOIN sme_working_capital.payments p
        ON i.invoice_id = p.invoice_id
        AND p.payment_date <= '2026-10-21'
    WHERE i.invoice_date <= '2026-10-21'
    GROUP BY
        i.customer_id,
        i.invoice_id,
        i.due_date,
        i.invoice_amount
) x ON c.customer_id = x.customer_id
WHERE x.due_date < '2026-10-21'
  AND x.outstanding_amount > 0
GROUP BY c.customer_id, c.customer_name
ORDER BY overdue_amount DESC
LIMIT 10;

USE sme_working_capital;
CREATE OR REPLACE VIEW vw_invoice_payment_summary AS
SELECT
    i.invoice_id,
    i.customer_id,
    i.invoice_date,
    i.due_date,
    i.invoice_amount,
    COALESCE(p.total_paid, 0) AS total_paid,
    i.invoice_amount - COALESCE(p.total_paid, 0)
        AS outstanding_amount,
    GREATEST(
        DATEDIFF('2026-10-21', i.due_date), 0
    ) AS days_overdue
FROM invoices i
LEFT JOIN (
    SELECT
        invoice_id,
        SUM(amount_paid) AS total_paid
    FROM payments
    WHERE payment_date <= '2026-10-21'
    GROUP BY invoice_id
) p ON i.invoice_id = p.invoice_id
WHERE i.invoice_date <= '2026-10-21';

CREATE OR REPLACE VIEW vw_customer_payment_risk AS
SELECT
    c.customer_id,
    c.customer_name,
    COUNT(v.invoice_id) AS total_invoices,
    ROUND(SUM(GREATEST(v.outstanding_amount, 0)), 2)
        AS total_outstanding,
    SUM(
        CASE
            WHEN v.days_overdue > 0
             AND v.outstanding_amount > 0
            THEN 1 ELSE 0
        END
    ) AS overdue_invoice_count,
    MAX(
        CASE
            WHEN v.outstanding_amount > 0
            THEN v.days_overdue ELSE 0
        END
    ) AS max_days_overdue,
    CASE
        WHEN MAX(
            CASE
                WHEN v.outstanding_amount > 0
                THEN v.days_overdue ELSE 0
            END
        ) > 90 THEN 'High Risk'
        WHEN MAX(
            CASE
                WHEN v.outstanding_amount > 0
                THEN v.days_overdue ELSE 0
            END
        ) > 30 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM customers c
LEFT JOIN vw_invoice_payment_summary v
    ON c.customer_id = v.customer_id
GROUP BY c.customer_id, c.customer_name;

SELECT
    risk_category,
    COUNT(*) AS total_customers,
    ROUND(SUM(total_outstanding), 2) AS total_outstanding
FROM sme_working_capital.vw_customer_payment_risk
GROUP BY risk_category
ORDER BY
    CASE risk_category
        WHEN 'High Risk' THEN 1
        WHEN 'Medium Risk' THEN 2
        WHEN 'Low Risk' THEN 3
    END;
    
    CREATE OR REPLACE VIEW
sme_working_capital.vw_cashflow_outlook AS
SELECT
    CASE
        WHEN due_date > '2026-10-21'
         AND due_date <= '2026-10-28'
            THEN 'Next 7 Days'
        WHEN due_date > '2026-10-28'
         AND due_date <= '2026-11-20'
            THEN 'Days 8-30'
        WHEN due_date > '2026-11-20'
         AND due_date <= '2026-12-20'
            THEN 'Days 31-60'
        ELSE 'Outside Window'
    END AS cashflow_period,
    COUNT(*) AS invoice_count,
    ROUND(SUM(outstanding_amount), 2)
        AS expected_receivables
FROM sme_working_capital.vw_invoice_payment_summary
WHERE outstanding_amount > 0
  AND due_date > '2026-10-21'
GROUP BY cashflow_period;

SELECT
    cashflow_period,
    invoice_count,
    expected_receivables
FROM sme_working_capital.vw_cashflow_outlook
ORDER BY
    CASE cashflow_period
        WHEN 'Next 7 Days' THEN 1
        WHEN 'Days 8-30' THEN 2
        WHEN 'Days 31-60' THEN 3
        ELSE 4
    END;
    
    SELECT
    risk_category,
    COUNT(*) AS customer_count,
    ROUND(SUM(total_outstanding), 2) AS outstanding_amount
FROM sme_working_capital.vw_customer_payment_risk
GROUP BY risk_category
ORDER BY outstanding_amount DESC;
    
