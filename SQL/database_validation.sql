USE sme_working_capital;
SHOW TABLES;

USE sme_working_capital;
SELECT 'customers' AS table_name, COUNT(*) AS rows_count FROM customers
UNION ALL
SELECT 'invoices', COUNT(*) FROM invoices
UNION ALL
SELECT 'payments', COUNT(*) FROM payments
UNION ALL
SELECT 'sales', COUNT(*) FROM sales
UNION ALL
SELECT 'expenses_payables', COUNT(*) FROM expenses_payables;

USE sme_working_capital;
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME,
    CONSTRAINT_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'sme_working_capital'
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, COLUMN_NAME;

USE sme_working_capital;
SHOW CREATE TABLE invoices;

SHOW CREATE TABLE invoices;

USE sme_working_capital;
SHOW CREATE TABLE payments;

SHOW CREATE TABLE sales;

SHOW CREATE TABLE expenses_payables;

USE sme_working_capital;
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'sme_working_capital'
  AND TABLE_NAME IN (
      'customers',
      'invoices',
      'payments',
      'sales',
      'expenses_payables'
  )
ORDER BY TABLE_NAME, ORDINAL_POSITION;

SHOW GLOBAL VARIABLES LIKE 'local_infile';

SET GLOBAL local_infile = ON;


USE sme_working_capital;
CREATE TABLE invoices_staging LIKE invoices;
SELECT COUNT(*) AS staging_rows
FROM invoices_staging;


SELECT COUNT(*) AS staging_rows
FROM sme_working_capital.invoices_staging;

