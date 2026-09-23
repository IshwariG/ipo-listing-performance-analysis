CREATE DATABASE ipo_db;
use ipo_db;
/* =====================================================================
   IPO ANALYSIS - MySQL QUERIES              database: ipo_db, table: ipo_clean
   Step 1: run ipo_mysql_setup.sql once (creates the database and loads the data).
   Step 2: run these queries one at a time (select a query, press Ctrl+Enter in
           MySQL Workbench).  Needs MySQL 8.0+ (uses WITH and window functions).
   ===================================================================== */

USE ipo_db;

/* ---------------------------------------------------------------------
   KEYWORD GLOSSARY - every keyword / symbol used in this file
   ---------------------------------------------------------------------
   USE db        work inside database db (must be run once at the top)
   SELECT        choose which columns (or calculations) to show
   FROM          which table the data comes from
   WHERE         keep only rows that meet a condition (filters BEFORE grouping)
   GROUP BY      make one result row per group (e.g. per year)
   HAVING        filter groups AFTER grouping (WHERE cannot use COUNT/AVG)
   ORDER BY      sort the result;  ASC = small to large,  DESC = large to small
   LIMIT n       show only the first n rows
   AS            give a column or table a nicer name (alias)
   DISTINCT      count/show each different value only once
   COUNT(*)      number of rows;  COUNT(col) counts non-empty values only
   SUM(col)      total of a column
   AVG(col)      average of a column
   MIN / MAX     smallest / largest value
   ROUND(x, 2)   round x to 2 decimal places
   CASE WHEN a THEN b ELSE c END   if-else inside a query (used to make buckets)
   AND           both conditions must be true
   OR            at least one condition must be true
   NOT           reverses a condition
   =  <>  <  >  <=  >=    equal, not equal, less, greater, less-or-equal, greater-or-equal
   IN ('a','b')  value matches any item in the list
   BETWEEN a AND b   value from a to b, both ends included
   IS NULL / IS NOT NULL   value is missing / is present  (never use = NULL)
   * / + - /     multiply, add, subtract, divide.  100.0 (not 100) forces decimal division
   MONTH(date)   the month number (1-12) of a DATE column
   WITH name AS (...)   CTE: a named temporary result you can query like a table
   Subquery      a SELECT inside brackets ( ) used inside another query
   OVER (...)    turns an aggregate/ranking function into a WINDOW function:
                 it calculates across related rows WITHOUT collapsing them
   PARTITION BY  inside OVER: restart the calculation for each group
   RANK()        rank rows (ties share a rank, next rank is skipped)
   ROW_NUMBER()  1,2,3... with no ties
   LAG(col)      value from the previous row (used for year-over-year change)
   SUM(...) OVER (ORDER BY ...)   running / cumulative total
   --  (two dashes)  a comment: the rest of that line is ignored by the database
   --------------------------------------------------------------------- */


/* =====================================================================
   SECTION A - "HOW MANY?" QUESTIONS
   ===================================================================== */

-- A1. Dataset size and period
SELECT COUNT(*)            AS total_ipos,
       COUNT(DISTINCT sector) AS sectors,
       MIN(listing_date)   AS first_listing,
       MAX(listing_date)   AS last_listing
FROM ipo_clean;

-- A2. How many IPOs listed per year (with share of total)
SELECT listing_year,
       COUNT(*)                                            AS ipos,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM ipo_clean), 1) AS pct_of_total
FROM ipo_clean
GROUP BY listing_year
ORDER BY listing_year;

-- A3. IPOs per year, split into SME vs Mainboard
SELECT listing_year,
       SUM(CASE WHEN ipo_type = 'SME'       THEN 1 ELSE 0 END) AS sme_ipos,
       SUM(CASE WHEN ipo_type = 'Mainboard' THEN 1 ELSE 0 END) AS mainboard_ipos,
       COUNT(*)                                                AS total_ipos
FROM ipo_clean
GROUP BY listing_year
ORDER BY listing_year;

-- A4. IPOs per quarter (busiest quarters first)
SELECT listing_quarter, COUNT(*) AS ipos
FROM ipo_clean
GROUP BY listing_quarter
ORDER BY ipos DESC
LIMIT 10;

-- A5. IPOs per sector
SELECT sector, COUNT(*) AS ipos
FROM ipo_clean
GROUP BY sector
ORDER BY ipos DESC;

-- A6. IPOs per exchange
SELECT exchange, ipo_type, COUNT(*) AS ipos
FROM ipo_clean
GROUP BY exchange, ipo_type
ORDER BY ipos DESC;

-- A7. IPOs per performance category, with percentage share
SELECT performance_category,
       COUNT(*) AS ipos,
       ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM ipo_clean), 1) AS pct_share
FROM ipo_clean
GROUP BY performance_category
ORDER BY ipos DESC;

-- A8. How many IPOs listed at a gain, flat, or a loss
SELECT CASE WHEN listing_gain_pct > 3  THEN 'Gain (> 3%)'
            WHEN listing_gain_pct < -3 THEN 'Loss (< -3%)'
            ELSE 'Flat (-3% to 3%)' END AS outcome,
       COUNT(*) AS ipos
FROM ipo_clean
GROUP BY outcome;


/* =====================================================================
   SECTION B - PERFORMANCE QUESTIONS
   ===================================================================== */

-- B1. Average listing gain and 1-month return by year
SELECT listing_year,
       COUNT(*)                          AS ipos,
       ROUND(AVG(listing_gain_pct), 2)   AS avg_listing_gain,
       ROUND(AVG(return_1m_pct), 2)      AS avg_1m_return,
       ROUND(AVG(positive_listing) * 100, 1) AS pct_listed_at_gain
FROM ipo_clean
GROUP BY listing_year
ORDER BY listing_year;

-- B2. SME vs Mainboard scorecard
SELECT ipo_type,
       COUNT(*)                        AS ipos,
       ROUND(AVG(listing_gain_pct), 2) AS avg_gain,
       ROUND(MIN(listing_gain_pct), 2) AS worst_gain,
       ROUND(MAX(listing_gain_pct), 2) AS best_gain,
       ROUND(AVG(subscription_times), 2)  AS avg_subscription_x,
       ROUND(AVG(min_investment_rs), 0)   AS avg_cost_of_one_lot_rs
FROM ipo_clean
GROUP BY ipo_type;

-- B3. Sector performance (only sectors with at least 200 IPOs)
SELECT sector,
       COUNT(*)                        AS ipos,
       ROUND(AVG(listing_gain_pct), 2) AS avg_gain,
       ROUND(AVG(positive_listing) * 100, 1) AS pct_listed_at_gain
FROM ipo_clean
GROUP BY sector
HAVING COUNT(*) >= 200
ORDER BY avg_gain DESC;

-- B4. Does higher subscription mean higher listing gain? (buckets built with CASE WHEN)
SELECT CASE WHEN subscription_times < 1  THEN '1. under 1x'
            WHEN subscription_times < 3  THEN '2. 1x to 3x'
            WHEN subscription_times < 10 THEN '3. 3x to 10x'
            WHEN subscription_times < 30 THEN '4. 10x to 30x'
            ELSE                              '5. 30x and above' END AS subscription_level,
       COUNT(*)                        AS ipos,
       ROUND(AVG(listing_gain_pct), 2) AS avg_gain,
       ROUND(AVG(positive_listing) * 100, 1) AS pct_listed_at_gain
FROM ipo_clean
WHERE subscription_times IS NOT NULL
GROUP BY subscription_level
ORDER BY subscription_level;

-- B5. Top 10 and bottom 10 IPOs by listing gain
SELECT ipo_id, company_name, sector, ipo_type, listing_year, subscription_times, listing_gain_pct
FROM ipo_clean
ORDER BY listing_gain_pct DESC
LIMIT 10;

SELECT ipo_id, company_name, sector, ipo_type, listing_year, subscription_times, listing_gain_pct
FROM ipo_clean
ORDER BY listing_gain_pct ASC
LIMIT 10;

-- B6. Heavily subscribed (10x or more) yet listed at a loss
SELECT COUNT(*) AS oversubscribed_ipos,
       SUM(CASE WHEN listing_gain_pct < 0 THEN 1 ELSE 0 END) AS still_lost_money,
       ROUND(SUM(CASE WHEN listing_gain_pct < 0 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS pct_lost
FROM ipo_clean
WHERE subscription_times >= 10;

-- B7. Sector x year grid of average listing gain
SELECT sector,
       ROUND(AVG(CASE WHEN listing_year = 2020 THEN listing_gain_pct END), 1) AS y2020,
       ROUND(AVG(CASE WHEN listing_year = 2021 THEN listing_gain_pct END), 1) AS y2021,
       ROUND(AVG(CASE WHEN listing_year = 2022 THEN listing_gain_pct END), 1) AS y2022,
       ROUND(AVG(CASE WHEN listing_year = 2023 THEN listing_gain_pct END), 1) AS y2023,
       ROUND(AVG(CASE WHEN listing_year = 2024 THEN listing_gain_pct END), 1) AS y2024,
       ROUND(AVG(CASE WHEN listing_year = 2025 THEN listing_gain_pct END), 1) AS y2025
FROM ipo_clean
GROUP BY sector
ORDER BY sector;

-- B8. Do listing gains last? Compare listing day with 1 month later, per category
SELECT performance_category,
       COUNT(*)                        AS ipos,
       ROUND(AVG(listing_gain_pct), 2) AS avg_listing_gain,
       ROUND(AVG(return_1m_pct), 2)    AS avg_1m_return,
       ROUND(AVG(return_1m_pct) - AVG(listing_gain_pct), 2) AS change_after_listing
FROM ipo_clean
GROUP BY performance_category
ORDER BY avg_listing_gain DESC;

-- B9. Sectors that beat the overall average gain (uses a subquery)
SELECT sector, ROUND(AVG(listing_gain_pct), 2) AS avg_gain
FROM ipo_clean
GROUP BY sector
HAVING AVG(listing_gain_pct) > (SELECT AVG(listing_gain_pct) FROM ipo_clean)
ORDER BY avg_gain DESC;

-- B10. SME IPOs listed at a gain with 10x+ subscription in Technology or Pharma (AND / OR / IN / BETWEEN)
SELECT company_name, sector, subscription_times, listing_gain_pct
FROM ipo_clean
WHERE ipo_type = 'SME'
  AND subscription_times >= 10
  AND sector IN ('Technology', 'Pharma & Healthcare')
  AND listing_gain_pct BETWEEN 20 AND 60
ORDER BY listing_gain_pct DESC
LIMIT 10;


/* =====================================================================
   SECTION C - ADVANCED (CTE + WINDOW FUNCTIONS)
   ===================================================================== */

-- C1. Best sector in every year (RANK inside each year)
WITH sector_year AS (
    SELECT listing_year, sector,
           ROUND(AVG(listing_gain_pct), 2) AS avg_gain
    FROM ipo_clean
    GROUP BY listing_year, sector
),
ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY listing_year ORDER BY avg_gain DESC) AS rnk
    FROM sector_year
)
SELECT listing_year, sector, avg_gain
FROM ranked
WHERE rnk = 1
ORDER BY listing_year;

-- C2. Year-over-year change in the number of IPOs (LAG = previous year's value)
WITH yearly AS (
    SELECT listing_year, COUNT(*) AS ipos
    FROM ipo_clean
    GROUP BY listing_year
)
SELECT listing_year,
       ipos,
       LAG(ipos) OVER (ORDER BY listing_year) AS previous_year,
       ROUND((ipos - LAG(ipos) OVER (ORDER BY listing_year)) * 100.0
             / LAG(ipos) OVER (ORDER BY listing_year), 1) AS yoy_change_pct
FROM yearly
ORDER BY listing_year;

-- C3. Running (cumulative) count of IPOs over the years
WITH yearly AS (
    SELECT listing_year, COUNT(*) AS ipos
    FROM ipo_clean
    GROUP BY listing_year
)
SELECT listing_year,
       ipos,
       SUM(ipos) OVER (ORDER BY listing_year) AS cumulative_ipos
FROM yearly
ORDER BY listing_year;

-- C4. Best IPO in each sector (ROW_NUMBER inside each sector)
WITH ranked AS (
    SELECT sector, company_name, ipo_id, listing_year, listing_gain_pct,
           ROW_NUMBER() OVER (PARTITION BY sector ORDER BY listing_gain_pct DESC) AS rn
    FROM ipo_clean
)
SELECT sector, company_name, ipo_id, listing_year, listing_gain_pct
FROM ranked
WHERE rn = 1
ORDER BY listing_gain_pct DESC;

-- C5. Each IPO's gain compared with its own sector's average
SELECT ipo_id, sector, listing_gain_pct,
       ROUND(AVG(listing_gain_pct) OVER (PARTITION BY sector), 2) AS sector_avg,
       ROUND(listing_gain_pct - AVG(listing_gain_pct) OVER (PARTITION BY sector), 2) AS vs_sector_avg
FROM ipo_clean
ORDER BY vs_sector_avg DESC
LIMIT 10;

-- C6. Busiest month for IPOs
SELECT MONTH(listing_date)             AS month_number,
       COUNT(*)                        AS ipos,
       ROUND(AVG(listing_gain_pct), 2) AS avg_gain
FROM ipo_clean
GROUP BY MONTH(listing_date)
ORDER BY month_number;


/* =====================================================================
   SECTION D - DATA-QUALITY CHECKS (what the cleaning step repaired)
   The flag_ columns record every row that was repaired in Python.
   ===================================================================== */

-- D1. Rows repaired during cleaning
SELECT SUM(CASE WHEN flag_gain_filled     = 1 THEN 1 ELSE 0 END) AS gain_recomputed,
       SUM(CASE WHEN flag_price_fixed     = 1 THEN 1 ELSE 0 END) AS price_corrected,
       SUM(CASE WHEN flag_size_sign_fixed = 1 THEN 1 ELSE 0 END) AS negative_size_fixed
FROM ipo_clean;

-- D2. Values that were genuinely missing and were left empty (NULL)
SELECT SUM(CASE WHEN issue_size_cr      IS NULL THEN 1 ELSE 0 END) AS missing_issue_size,
       SUM(CASE WHEN subscription_times IS NULL THEN 1 ELSE 0 END) AS missing_subscription,
       SUM(CASE WHEN qib_subscription_x IS NULL THEN 1 ELSE 0 END) AS missing_qib
FROM ipo_clean;