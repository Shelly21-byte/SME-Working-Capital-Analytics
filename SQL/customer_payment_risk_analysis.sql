
USE sme_working_capital;
LOAD DATA LOCAL INFILE
'C:/path/to/SME-Working-Capital-Analytics/DATA/invoices.csv'
INTO TABLE invoices_staging
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(invoice_id, customer_id, invoice_date,
 due_date, invoice_amount, invoice_status);


SELECT
    COUNT(*) AS total_invoices,
    COUNT(DISTINCT invoice_id) AS unique_invoices,
    MIN(invoice_date) AS first_invoice_date,
    MAX(invoice_date) AS last_invoice_date,
    SUM(invoice_amount IS NULL) AS missing_amounts
FROM sme_working_capital.invoices_staging;


SELECT
    (SELECT COUNT(*)
     FROM invoices_staging s
     LEFT JOIN invoices i
       ON s.invoice_id = i.invoice_id
     WHERE i.invoice_id IS NULL) AS new_invoice_ids,

    (SELECT COUNT(*)
     FROM invoices i
     LEFT JOIN invoices_staging s
       ON i.invoice_id = s.invoice_id
     WHERE s.invoice_id IS NULL) AS missing_old_ids;
     
     
SELECT
    COUNT(*) AS invalid_customer_references
FROM sme_working_capital.invoices_staging s
LEFT JOIN sme_working_capital.customers c
    ON s.customer_id = c.customer_id
WHERE c.customer_id IS NULL;


SELECT
    SUM(invoice_amount <= 0) AS invalid_amounts,
    SUM(invoice_date IS NULL) AS missing_invoice_dates,
    SUM(due_date IS NULL) AS missing_due_dates,
    SUM(due_date < invoice_date) AS invalid_due_dates
FROM sme_working_capital.invoices_staging;


SELECT
    COUNT(*) AS invoices_with_overpayment,
    ROUND(COALESCE(SUM(
        GREATEST(COALESCE(p.total_paid, 0) - s.invoice_amount, 0)
    ), 0), 2) AS total_overpayment
FROM sme_working_capital.invoices_staging s
LEFT JOIN (
    SELECT
        invoice_id,
        SUM(amount_paid) AS total_paid
    FROM sme_working_capital.payments
    GROUP BY invoice_id
) p ON s.invoice_id = p.invoice_id
WHERE COALESCE(p.total_paid, 0) > s.invoice_amount;


SELECT
    COUNT(*) AS total_invoices,
    SUM(
        CASE
            WHEN s.invoice_amount < i.invoice_amount THEN 1
            ELSE 0
        END
    ) AS decreased_amounts,
    SUM(
        CASE
            WHEN s.invoice_amount > i.invoice_amount THEN 1
            ELSE 0
        END
    ) AS increased_amounts,
    SUM(
        CASE
            WHEN s.invoice_amount = i.invoice_amount THEN 1
            ELSE 0
        END
    ) AS unchanged_amounts
FROM sme_working_capital.invoices_staging s
JOIN sme_working_capital.invoices i
    ON s.invoice_id = i.invoice_id;
    
    
SELECT
    COUNT(*) AS invoices_with_overpayment,
    ROUND(
        SUM(p.total_paid - i.invoice_amount), 2
    ) AS total_overpayment
FROM sme_working_capital.invoices i
JOIN (
    SELECT
        invoice_id,
        SUM(amount_paid) AS total_paid
    FROM sme_working_capital.payments
    GROUP BY invoice_id
) p
    ON i.invoice_id = p.invoice_id
WHERE p.total_paid > i.invoice_amount;


CREATE TABLE sme_working_capital.invoices_original_backup
AS
SELECT *
FROM sme_working_capital.invoices;


SELECT COUNT(*) AS backup_rows
FROM sme_working_capital.invoices_original_backup;


SELECT
    invoice_id,
    customer_id,
    invoice_amount
FROM sme_working_capital.invoices
LIMIT 10;


SELECT
    invoice_id,
    customer_id,
    invoice_amount
FROM sme_working_capital.invoices
ORDER BY invoice_id;

SELECT
    COUNT(*) AS backup_rows,
    COUNT(DISTINCT invoice_id) AS unique_invoices
FROM sme_working_capital.invoices_original_backup;

SELECT
    COUNT(*) AS staging_rows,
    COUNT(DISTINCT invoice_id) AS unique_invoices,
    MIN(invoice_date) AS earliest_invoice,
    MAX(invoice_date) AS latest_invoice
FROM sme_working_capital.invoices_staging;

SELECT
    COUNT(*) AS total_invoices,
    SUM(CASE WHEN invoice_amount IS NULL
        OR invoice_amount <= 0 THEN 1 ELSE 0 END)
        AS invalid_amounts,
    SUM(CASE WHEN c.customer_id IS NULL
        THEN 1 ELSE 0 END)
        AS invalid_customers
FROM sme_working_capital.invoices_staging s
LEFT JOIN sme_working_capital.customers c
    ON s.customer_id = c.customer_id;
    
    SELECT
    COUNT(*) AS invoices_with_overpayment,
    COALESCE(
        ROUND(SUM(p.total_paid - s.invoice_amount), 2),
        0
    ) AS total_overpayment
FROM sme_working_capital.invoices_staging s
JOIN (
    SELECT
        invoice_id,
        SUM(amount_paid) AS total_paid
    FROM sme_working_capital.payments
    GROUP BY invoice_id
) p
    ON s.invoice_id = p.invoice_id
WHERE p.total_paid > s.invoice_amount;


CREATE TABLE sme_working_capital.payments_original_backup
LIKE sme_working_capital.payments;
INSERT INTO sme_working_capital.payments_original_backup
SELECT *
FROM sme_working_capital.payments;
SELECT COUNT(*) AS backup_rows
FROM sme_working_capital.payments_original_backup;

SELECT
    (SELECT COUNT(*)
     FROM sme_working_capital.payments) AS original_rows,
    (SELECT COUNT(*)
     FROM sme_working_capital.payments_original_backup) AS backup_rows;

CREATE TABLE sme_working_capital.payments_staging
LIKE sme_working_capital.payments;

LOAD DATA LOCAL INFILE
'C:/Users/shell/Downloads/SME-Working-Capital-Analytics/DATA/payments.csv'
INTO TABLE sme_working_capital.payments_staging
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(payment_id, invoice_id, payment_date, amount_paid, payment_method);

SELECT
    COUNT(*) AS staging_rows,
    COUNT(DISTINCT payment_id) AS unique_payments,
    MIN(payment_date) AS earliest_payment,
    MAX(payment_date) AS latest_payment
FROM sme_working_capital.payments_staging;

SELECT
    COUNT(*) AS invalid_invoice_references
FROM sme_working_capital.payments_staging p
LEFT JOIN sme_working_capital.invoices_staging i
    ON p.invoice_id = i.invoice_id
WHERE i.invoice_id IS NULL;

SELECT
    COUNT(*) AS overpaid_invoices,
    COALESCE(
        ROUND(SUM(p.total_paid - i.invoice_amount), 2),
        0
    ) AS excess_payment
FROM sme_working_capital.invoices_staging i
JOIN (
    SELECT
        invoice_id,
        SUM(amount_paid) AS total_paid
    FROM sme_working_capital.payments_staging
    GROUP BY invoice_id
) p ON i.invoice_id = p.invoice_id
WHERE p.total_paid > i.invoice_amount + 0.01;

CREATE TABLE sme_working_capital.sales_staging
LIKE sme_working_capital.sales;
SELECT COUNT(*) AS staging_rows
FROM sme_working_capital.sales_staging;

LOAD DATA LOCAL INFILE
'C:/Users/shell/Downloads/SME-Working-Capital-Analytics/DATA/sales.csv'
INTO TABLE sme_working_capital.sales_staging
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(sale_id, invoice_id, product_id, product_category,
 quantity, unit_price, sales_amount);
 
 SELECT
    COUNT(*) AS total_sales,
    COUNT(DISTINCT sale_id) AS unique_sales,
    COUNT(DISTINCT invoice_id) AS linked_invoices
FROM sme_working_capital.sales_staging;

SELECT COUNT(*) AS invalid_invoice_references
FROM sme_working_capital.sales_staging s
LEFT JOIN sme_working_capital.invoices_staging i
    ON s.invoice_id = i.invoice_id
WHERE i.invoice_id IS NULL;

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'sme_working_capital'
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, COLUMN_NAME;
 
 CREATE TABLE sme_working_capital.sales_original_backup
LIKE sme_working_capital.sales;
INSERT INTO sme_working_capital.sales_original_backup
SELECT * FROM sme_working_capital.sales;

SELECT
    'Invoices' AS dataset,
    (SELECT COUNT(*) FROM sme_working_capital.invoices_original_backup) AS backup_rows,
    (SELECT COUNT(*) FROM sme_working_capital.invoices_staging) AS staging_rows
UNION ALL
SELECT
    'Payments',
    (SELECT COUNT(*) FROM sme_working_capital.payments_original_backup),
    (SELECT COUNT(*) FROM sme_working_capital.payments_staging)
UNION ALL
SELECT
    'Sales',
    (SELECT COUNT(*) FROM sme_working_capital.sales_original_backup),
    (SELECT COUNT(*) FROM sme_working_capital.sales_staging);
    
    SELECT COUNT(*) AS missing_customers
FROM sme_working_capital.invoices_staging i
LEFT JOIN sme_working_capital.customers c
    ON i.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT
    TABLE_NAME,
    ORDINAL_POSITION,
    COLUMN_NAME,
    DATA_TYPE
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'sme_working_capital'
  AND TABLE_NAME IN (
      'invoices',
      'invoices_staging',
      'payments',
      'payments_staging',
      'sales',
      'sales_staging'
  )
ORDER BY
    FIELD(
        TABLE_NAME,
        'invoices', 'invoices_staging',
        'payments', 'payments_staging',
        'sales', 'sales_staging'
    ),
    ORDINAL_POSITION;
    
    SELECT
    original.TABLE_NAME AS original_table,
    original.COLUMN_NAME,
    original.DATA_TYPE AS original_type,
    staging.DATA_TYPE AS staging_type,
    staging.COLUMN_NAME AS staging_column
FROM information_schema.COLUMNS original
LEFT JOIN information_schema.COLUMNS staging
    ON staging.TABLE_SCHEMA = original.TABLE_SCHEMA
    AND staging.TABLE_NAME = CONCAT(original.TABLE_NAME, '_staging')
    AND staging.ORDINAL_POSITION = original.ORDINAL_POSITION
WHERE original.TABLE_SCHEMA = 'sme_working_capital'
    AND original.TABLE_NAME IN ('invoices', 'payments', 'sales')
    AND (
        staging.COLUMN_NAME IS NULL
        OR original.COLUMN_NAME <> staging.COLUMN_NAME
        OR original.COLUMN_TYPE <> staging.COLUMN_TYPE
    );
    
    SET autocommit = 0;
    
    SELECT @@autocommit AS autocommit_status;
    
    START TRANSACTION;
    DELETE FROM sme_working_capital.payments;
DELETE FROM sme_working_capital.sales;
UPDATE sme_working_capital.invoices i
JOIN sme_working_capital.invoices_staging s
    ON i.invoice_id = s.invoice_id
SET
    i.customer_id = s.customer_id,
    i.invoice_date = s.invoice_date,
    i.due_date = s.due_date,
    i.invoice_amount = s.invoice_amount,
    i.invoice_status = s.invoice_status;
INSERT INTO sme_working_capital.payments
SELECT * FROM sme_working_capital.payments_staging;
INSERT INTO sme_working_capital.sales
SELECT * FROM sme_working_capital.sales_staging;

ROLLBACK;

USE sme_working_capital;
START TRANSACTION;
DELETE FROM payments;
DELETE FROM sales;
UPDATE invoices i
JOIN invoices_staging s
    ON i.invoice_id = s.invoice_id
SET
    i.customer_id = s.customer_id,
    i.invoice_date = s.invoice_date,
    i.due_date = s.due_date,
    i.invoice_amount = s.invoice_amount,
    i.invoice_status = s.invoice_status;
INSERT INTO payments
SELECT * FROM payments_staging;
INSERT INTO sales
SELECT * FROM sales_staging;
SELECT
    (SELECT COUNT(*) FROM invoices) AS invoices_count,
    (SELECT COUNT(*) FROM payments) AS payments_count,
    (SELECT COUNT(*) FROM sales) AS sales_count;
    
    SELECT
    (SELECT COUNT(*) FROM sme_working_capital.invoices) AS invoices,
    (SELECT COUNT(*) FROM sme_working_capital.payments) AS payments,
    (SELECT COUNT(*) FROM sme_working_capital.sales) AS sales;
    
    USE sme_working_capital;
DELIMITER $$
DROP PROCEDURE IF EXISTS apply_corrected_data$$
CREATE PROCEDURE apply_corrected_data()
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    START TRANSACTION;
    DELETE FROM payments;
    DELETE FROM sales;
    UPDATE invoices i
    JOIN invoices_staging s
        ON i.invoice_id = s.invoice_id
    SET
        i.customer_id = s.customer_id,
        i.invoice_date = s.invoice_date,
        i.due_date = s.due_date,
        i.invoice_amount = s.invoice_amount,
        i.invoice_status = s.invoice_status;
    INSERT INTO payments
    SELECT * FROM payments_staging;
    INSERT INTO sales
    SELECT * FROM sales_staging;
    -- Verify row counts before committing
    IF (SELECT COUNT(*) FROM invoices) <> 100000
       OR (SELECT COUNT(*) FROM payments) <> 124017
       OR (SELECT COUNT(*) FROM sales) <> 199760
    THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Row count mismatch. Changes rolled back.';
    END IF;
    COMMIT;
END$$
DELIMITER ;

CALL sme_working_capital.apply_corrected_data();

SET SQL_SAFE_UPDATES = 0;
CALL sme_working_capital.apply_corrected_data();

SELECT
    (SELECT COUNT(*) FROM sme_working_capital.invoices) AS invoices,
    (SELECT COUNT(*) FROM sme_working_capital.payments) AS payments,
    (SELECT COUNT(*) FROM sme_working_capital.sales) AS sales;
    
    SHOW CREATE VIEW sme_working_capital.vw_invoice_payment_summary;
    
    SHOW CREATE VIEW sme_working_capital.vw_invoice_payment_summary;
