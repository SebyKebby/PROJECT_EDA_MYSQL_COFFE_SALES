-- Active: 1720687396482@@127.0.0.1@3306@coffe_project

--DATA CLEANING

SELECT * 
FROM coffee_sales


-- 1. Data cleaning

-- Staging

CREATE TABLE coffee_sales_staging
LIKE coffee_sales;
INSERT coffee_sales_staging
SELECT *
FROM coffee_sales;

-- Using ROW_NUMBER() find duplicates
CREATE TABLE `coffee_sales_staging2` (
  `date` text,
  `datetime` text,
  `cash_type` text,
  `card` text,
  `money` double DEFAULT NULL,
  `coffee_name` text,
  `row_num` INT
  
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci


INSERT INTO coffee_sales_staging2
SELECT *, ROW_NUMBER() OVER(PARTITION BY date,datetime,cash_type,card,money,coffee_name)   AS row_nu
FROM coffee_sales_staging;




DELETE 
FROM coffee_sales_staging2
WHERE row_num > 1;


-- Standardizing Data


--Removing row_num
ALTER TABLE coffee_sales_staging2
DROP COLUMN row_num;


-- We wont need the miliseconds of when people buy coffee,
UPDATE coffee_sales_staging2
SET datetime = SUBSTRING_INDEX(datetime, '.', 1);

-- As the date data already exist, the time in the datetime 

SELECT datetime,
    SUBSTRING_INDEX(datetime, ' ',-1 )
FROM coffee_sales_staging2;

UPDATE coffee_sales_staging2
set datetime =      SUBSTRING_INDEX(datetime, ' ',-1 );

SELECT DISTINCT card
FROM coffee_sales_staging2;


-- As the card table is mostly the same without much difference except the final section, we can remove the leading part for legibility

SELECT card,
SUBSTRING_INDEX(card, '-', -1)
FROM coffee_sales_staging2;

UPDATE coffee_sales_staging2
SET card = SUBSTRING_INDEX(card, '-', -1);


-- Change date formatting and data type
UPDATE coffee_sales_staging2
SET `date` = STR_TO_DATE(`date`, '%Y-%m-%d');

ALTER TABLE coffee_sales_staging2
MODIFY COLUMN `date` DATE;

-- Similarly , change datetime formatting and data type
SELECT datetime,
STR_TO_DATE(`datetime`, '%T')
FROM coffee_sales_staging2;

UPDATE coffee_sales_staging2
SET `datetime` = STR_TO_DATE(`datetime`, '%T');

ALTER TABLE coffee_sales_staging2
MODIFY COLUMN `datetime` TIME;

SELECT *
FROM coffee_sales_staging2;



--Finding null || From the look of it, the only column that contain empty data is money. Look for nulls and empties in money
SELECT *
from coffee_sales_staging2
WHERE card = '';

-- Filling the empty cells with 0000
SELECT *,
CASE WHEN card = '' THEN '0000'
    ELSE card
END AS card_filled
FROM coffee_sales_staging2

UPDATE coffee_sales_staging2
SET card = 
    CASE WHEN card = '' 
    THEN '0000' 
    ELSE card 
END

SELECT *
FROM coffee_sales_staging2


--Finished Data Cleaning





-- 2. EDA

-- What is the most popular coffee
SELECT 
    coffee_name,
    COUNT(coffee_name) AS freq
from coffee_sales_staging2
GROUP BY coffee_name
ORDER BY freq DESC;

-- Answer : Americano with MIlk, Latter and Cappuccino are the top 3 most popular with a large margin


-- pricing of coffees
SELECT DISTINCT
    coffee_name,
    money
FROM coffee_sales_staging2
ORDER BY coffee_name;

--each coffee has 4 varying price levels. Might be due to discount or Special programs

-- max/ min pricing for coffees
SELECT
    coffee_name,
    MAX(money),
    MIN(money)
FROM coffee_sales_staging2
GROUP BY coffee_name
ORDER BY coffee_name



--Income of the store
SELECT 
    ROUND(SUM(money))
FROM coffee_sales_staging2

--Income by month
SELECT 
    MONTH(`date`) as monthly,
    ROUND(SUM(money))
FROM coffee_sales_staging2
GROUP BY monthly
ORDER BY monthly

-- The month with lowest income was April, followed by March. May has the highest income out of all the months by a large margin

--Income by day
SELECT 
    DAY(`date`) as daily,
    ROUND(SUM(money)) as income
FROM coffee_sales_staging2
GROUP BY daily
ORDER BY income DESC


-- The middle of the month seems to bring the most income to the store.


--Income by hour
SELECT 
    SUBSTRING(`datetime`, 1, 2) AS hourly,
    ROUND(SUM(money)) as income
FROM coffee_sales_staging2
GROUP BY hourly
ORDER BY income DESC

-- Opening hour (10AM) generats the most income by a large margin. Followed by 19PM. Peak horus are generally around that time (lunch/dinner)



--Payement method


SELECT 
    card,
    COUNT(card) as purchase_freq
FROM coffee_sales_staging2
GROUP BY card
ORDER BY purchase_freq DESC;

SELECT
    COUNT(card)
FROM coffee_sales_staging2


SELECT 
    card,
    COUNT(card) AS purchase_freq,
    (COUNT(card) / (Select COUNT(card) FROM coffee_sales_staging2)) * 100 AS purchase_pct
FROM coffee_sales_staging2
GROUP BY card
ORDER BY purchase_pct DESC;


--Roll over income
WITH Rolling_Total AS
(    SELECT MONTH(`date`) AS `Month`,
    SUM(money) AS total_revenue
    FROM coffee_sales_staging2
    GROUP BY `Month`
)SELECT `Month`,
    SUM(total_revenue) OVER(ORDER BY Month) AS rolling_total
FROM `Rolling_Total`


--Daily ranking for each month
WITH Sales_Month AS
(
    SELECT MONTH(`date`) AS monthly,
    DAY(`date`), 
    ROUND(SUM(money)) as revenue
    FROM coffee_sales_staging2
    GROUP BY `date`
)
SELECT *,
DENSE_RANK() OVER (PARTITION BY monthly ORDER BY revenue)
FROM `Sales_Month`