-- ================================================
-- FINANCIAL TRANSACTION FRAUD DETECTION ANALYSIS PROJECT
-- Author: Aquib Tahil
-- Date: 2026
-- Dataset: PaySim Synthetic Financial Dataset
-- Total Records: 100,050 | Fraud Cases: 116
-- ================================================
-- SECTION 1: DATABASE SETUP
CREATE DATABASE fraud_detection;
USE fraud_detection;
CREATE TABLE transactions (
    step INT,
    type VARCHAR(20),
    amount DECIMAL(18,2),
    nameOrig VARCHAR(50),
    oldbalanceOrg DECIMAL(18,2),
    newbalanceOrig DECIMAL(18,2),
    nameDest VARCHAR(50),
    oldbalanceDest DECIMAL(18,2),
    newbalanceDest DECIMAL(18,2),
    isFraud TINYINT(1),
    isFlaggedFraud TINYINT(1),
    balanceDiscrepancy VARCHAR(5),
    systemMissedFraud VARCHAR(5)
);
SELECT *FROM transactions;
-- ================================================
-- SECTION 2: DATA IMPORT
LOAD DATA LOCAL INFILE 'C:/mysql_import/fraud_cleaned.csv'
INTO TABLE transactions
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;
-- ================================================
-- SECTION 3: DATA CLEANING
SET SQL_SAFE_UPDATES = 0;
UPDATE transactions 
SET systemMissedFraud = REPLACE(systemMissedFraud, '\r', '');
-- ================================================
-- SECTION 4: DATA CLEANING VERIFICATION
SELECT 
    COUNT(*) AS total_rows,
    SUM(isFraud) AS total_fraud,
    SUM(CASE WHEN systemMissedFraud = 'YES' THEN 1 ELSE 0 END) AS bank_missed_fraud,
    COUNT(DISTINCT type) AS transaction_types
FROM transactions;
-- ================================================
-- QUERIES
-- ================================================
-- Overall Fraud Summary 
SELECT 
    COUNT(*) AS total_transactions,
    SUM(isFraud) AS total_fraud,
    COUNT(*) - SUM(isFraud) AS total_legitimate,
    ROUND(SUM(isFraud) * 100.0 / COUNT(*), 2) AS fraud_percentage,
    ROUND(SUM(CASE WHEN systemMissedFraud = 'YES' THEN 1 ELSE 0 END) * 100.0 / SUM(isFraud), 2) AS bank_miss_rate
FROM transactions;
-- Fraud by Transaction Type 
SELECT 
    type,
    COUNT(*) AS total_transactions,
    SUM(isFraud) AS fraud_count,
    ROUND(SUM(isFraud) * 100.0 / COUNT(*), 2) AS fraud_rate_percentage
FROM transactions
GROUP BY type
ORDER BY fraud_count DESC;
-- Top 10 Highest Fraud Amounts 
SELECT 
    nameOrig,type,amount,oldbalanceOrg,
    newbalanceOrig,nameDest 
    FROM transactions
    WHERE isFraud=1 
    ORDER BY amount DESC
    LIMIT 10;
-- Balance Discrepancy Analysis
SELECT 
    type, COUNT(*)AS total_discrepancies,
    SUM(isFraud)AS fraud_with_discrepancy,
    ROUND(SUM(isFraud)*100/COUNT(*),2)AS fraud_rate
    FROM transactions
    WHERE balanceDiscrepancy='YES'
    GROUP BY type
    ORDER BY fraud_with_discrepancy DESC;
-- Fraud Rate by Transaction Type
SELECT 
    type,
    COUNT(*) AS total_transactions,
    SUM(isFraud) AS fraud_count,
    SUM(CASE WHEN balanceDiscrepancy = 'YES' THEN 1 ELSE 0 END) AS discrepancy_count,
    ROUND(SUM(isFraud) * 100.0 / COUNT(*), 2) AS fraud_rate,
    ROUND(SUM(CASE WHEN balanceDiscrepancy = 'YES' THEN 1 ELSE 0 END) * 100/ COUNT(*), 2) AS discrepancy_rate
FROM transactions
GROUP BY type
ORDER BY fraud_rate DESC;
-- Average Transaction Amount by Type
SELECT 
  type, ROUND(AVG(amount),2)AS avg_amount,
  ROUND(MIN(amount),2)AS min_amount,
  ROUND(MAX(amount),2)AS max_amount,
  ROUND(AVG(CASE WHEN isFraud=1 THEN amount END),2)AS avg_fraud_amount
FROM transactions 
GROUP BY type
ORDER BY AVG(amount) DESC;
-- Bank Missed Fraud Analysis
SELECT type,
  COUNT(*)AS total_fraud_cases,
  SUM(CASE WHEN systemMissedFraud='YES' THEN 1 ELSE 0 END)AS bank_missed,
  SUM(CASE WHEN systemMissedFraud='NO' THEN 1 ELSE 0 END)AS bank_caught,
  ROUND(SUM(CASE WHEN systemMissedFraud='YES' THEN 1 ELSE 0 END)*100/COUNT(*),2)AS miss_rate
FROM transactions
WHERE isFraud=1
GROUP BY type
ORDER BY miss_rate DESC;
--  High Risk Destination Accounts 
SELECT 
    nameDest, COUNT(*) AS total_received,
    SUM(isFraud) AS fraud_received,
    ROUND(SUM(CASE WHEN isFraud = 1 THEN amount ELSE 0 END), 2) AS total_fraud_amount,
    ROUND(SUM(isFraud) * 100.0 / COUNT(*), 2) AS fraud_rate
FROM transactions
WHERE isFraud = 1
GROUP BY nameDest
ORDER BY total_fraud_amount DESC
LIMIT 10; 
--  Customer Level Fraud Analysis
SELECT 
  nameOrig,
  COUNT(*)AS fraud_count,
  ROUND(SUM(amount),2)AS total_amount_lost,
  ROUND(AVG(amount),2)AS avg_fraud_amount 
FROM transactions
WHERE isFraud=1
GROUP BY nameOrig
ORDER BY fraud_count DESC, total_amount_lost DESC
LIMIT 10;
--  Fraud Detection Pattern 
SELECT 
  type,
  COUNT(*)AS total_fraud,
  SUM(CASE WHEN newbalanceOrig=0 THEN 1 ELSE 0 END)AS fully_drained,
  ROUND(SUM(CASE WHEN newbalanceOrig=0 THEN 1 ELSE 0 END)*100/COUNT(*))AS drain_rate
FROM transactions
WHERE isFraud=1
GROUP BY type
ORDER BY drain_rate DESC;
-- ================================================
-- END OF PROJECT
-- ================================================
 

