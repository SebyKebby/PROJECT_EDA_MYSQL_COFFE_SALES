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

