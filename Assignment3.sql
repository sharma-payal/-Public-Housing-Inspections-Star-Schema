/********************************************************************************************
   Payal Sharma - Assignment 3 (Public Housing Inspection Data)
   FULL END-TO-END SCRIPT (DB + TABLE + LOAD + FINAL Q5 OUTPUT)
   Notes:
   - CSV column order is (confirmed by your sample):
     INSPECTION_ID,
     PUBLIC_HOUSING_AGENCY_NAME,
     COST_OF_INSPECTION_IN_DOLLARS,
     INSPECTED_DEVELOPMENT_NAME,
     INSPECTED_DEVELOPMENT_ADDRESS,
     INSPECTED_DEVELOPMENT_CITY,
     INSPECTED_DEVELOPMENT_STATE,
     INSPECTION_DATE,
     INSPECTION_SCORE
********************************************************************************************/

-- =========================
-- A) ENVIRONMENT CHECKS
-- =========================
-- 1) Verify we are connected to a DB (if NULL, the script will create and use one)
SELECT DATABASE() AS current_db;

-- 2) Check MySQL version (important: window functions require MySQL 8.0+)
SELECT VERSION() AS mysql_version;

-- =========================
-- B) CREATE DATABASE + TABLE
-- =========================
DROP DATABASE IF EXISTS public_housing_db;
CREATE DATABASE public_housing_db;
USE public_housing_db;

DROP TABLE IF EXISTS public_housing_inspection_data;

CREATE TABLE public_housing_inspection_data (
    INSPECTION_ID INT,
    PUBLIC_HOUSING_AGENCY_NAME VARCHAR(255),
    COST_OF_INSPECTION_IN_DOLLARS INT,
    INSPECTED_DEVELOPMENT_NAME VARCHAR(255),
    INSPECTED_DEVELOPMENT_ADDRESS VARCHAR(255),
    INSPECTED_DEVELOPMENT_CITY VARCHAR(255),
    INSPECTED_DEVELOPMENT_STATE VARCHAR(20),
    INSPECTION_DATE VARCHAR(50),
    INSPECTION_SCORE INT
);

-- =========================
-- C) LOAD CSV (MAKE SURE local_infile is enabled on your server)
-- =========================
SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE '/Users/payalsharma/Downloads/public_housing_inspection_data.csv'
INTO TABLE public_housing_inspection_data
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(
  INSPECTION_ID,
  PUBLIC_HOUSING_AGENCY_NAME,
  COST_OF_INSPECTION_IN_DOLLARS,
  INSPECTED_DEVELOPMENT_NAME,
  INSPECTED_DEVELOPMENT_ADDRESS,
  INSPECTED_DEVELOPMENT_CITY,
  INSPECTED_DEVELOPMENT_STATE,
  INSPECTION_DATE,
  INSPECTION_SCORE
);

-- =========================
-- D) QUICK VALIDATION (RUN THESE AND CONFIRM)
-- =========================
-- 1) Row count 
SELECT COUNT(*) AS total_rows_loaded FROM public_housing_inspection_data;

-- 2) Sanity check: confirm columns are not shifted (look at first 5 rows)
SELECT *
FROM public_housing_inspection_data
LIMIT 5;

-- 3) Date conversion check (this must return real dates, not NULL)
SELECT
  INSPECTION_DATE,
  STR_TO_DATE(INSPECTION_DATE, '%m/%d/%Y') AS converted_date
FROM public_housing_inspection_data
LIMIT 10;

-- =========================
-- E) FINAL REQUIRED OUTPUT 
-- =========================
WITH cleaned AS (
    SELECT 
        PUBLIC_HOUSING_AGENCY_NAME AS PHA_NAME,
        COST_OF_INSPECTION_IN_DOLLARS AS INSPECTION_COST,
        STR_TO_DATE(INSPECTION_DATE, '%m/%d/%Y') AS INSPECTION_DATE
    FROM public_housing_inspection_data
    WHERE COST_OF_INSPECTION_IN_DOLLARS IS NOT NULL
      AND STR_TO_DATE(INSPECTION_DATE, '%m/%d/%Y') IS NOT NULL
),
analysis AS (
    SELECT 
        PHA_NAME,
        INSPECTION_DATE,
        INSPECTION_COST,
        ROW_NUMBER() OVER (
            PARTITION BY PHA_NAME
            ORDER BY INSPECTION_DATE DESC
        ) AS rn,
        LAG(INSPECTION_DATE, 1) OVER (
            PARTITION BY PHA_NAME
            ORDER BY INSPECTION_DATE DESC
        ) AS SECOND_MR_INSPECTION_DATE,
        LAG(INSPECTION_COST, 1) OVER (
            PARTITION BY PHA_NAME
            ORDER BY INSPECTION_DATE DESC
        ) AS SECOND_MR_INSPECTION_COST
    FROM cleaned
)
SELECT 
    PHA_NAME,
    INSPECTION_DATE AS MR_INSPECTION_DATE,
    INSPECTION_COST AS MR_INSPECTION_COST,
    SECOND_MR_INSPECTION_DATE,
    SECOND_MR_INSPECTION_COST,
    (INSPECTION_COST - SECOND_MR_INSPECTION_COST) AS CHANGE_IN_COST,
    ROUND(((INSPECTION_COST - SECOND_MR_INSPECTION_COST) / SECOND_MR_INSPECTION_COST) * 100, 2) AS PERCENT_CHANGE_IN_COST
FROM analysis
WHERE rn = 1
  AND SECOND_MR_INSPECTION_COST IS NOT NULL
  AND INSPECTION_COST > SECOND_MR_INSPECTION_COST
ORDER BY CHANGE_IN_COST DESC;



