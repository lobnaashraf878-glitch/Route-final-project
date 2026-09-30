CREATE DATABASE FOOD;
use FOOD;

-- Calendar Dimension (DIMENSION TABLES)

CREATE TABLE Calendar (
    date DATE PRIMARY KEY);
    ALTER TABLE Calendar
ADD 
    day_number INT,
    day_name VARCHAR(20),
    week_number INT,
    month_number INT,
    month_name VARCHAR(20),
    quarter_number INT,
    year_number INT;


    UPDATE Calendar
SET 
    day_number = DATEPART(DAY, date),
    day_name = DATENAME(WEEKDAY, date),
    week_number = DATEPART(WEEK, date),
    month_number = DATEPART(MONTH, date),
    month_name = DATENAME(MONTH, date),
    quarter_number = DATEPART(QUARTER, date),
    year_number = DATEPART(YEAR, date);

   ------------------------------------------------------
  
  -- Regions Dimension
CREATE TABLE Region(
    region_id        INTEGER PRIMARY KEY,
    sales_district   VARCHAR(100) NOT NULL,
    sales_region     VARCHAR(100) NOT NULL
);


----------------------------------------------------------

-- Stores Dimension
CREATE TABLE Stores (
    store_id              INTEGER PRIMARY KEY,
    region_id             INTEGER NOT NULL,
    store_type            VARCHAR(100),
    store_name            VARCHAR(100) NOT NULL,
    store_street_address  VARCHAR(255),
    store_city            VARCHAR(100),
    store_state           VARCHAR(100),
    store_country         VARCHAR(100),
    store_phone           VARCHAR(50),
    first_opened_date     DATE,
    last_remodel_date     DATE,
    total_sqft            INTEGER,
    grocery_sqft          INTEGER,

    CONSTRAINT fk_stores_region
        FOREIGN KEY (region_id)
        REFERENCES Region(region_id)
);
---------------------------------------------------------------------
-- Products Dimension
CREATE TABLE Products (
    product_id           INT PRIMARY KEY,
    product_brand        VARCHAR(100) NOT NULL,
    product_name         VARCHAR(255) NOT NULL,
    product_sku          BIGINT       NOT NULL UNIQUE,
    product_retail_price DECIMAL(10,2) NOT NULL,
    product_cost         DECIMAL(10,2) NOT NULL,
    product_weight       DECIMAL(10,2),
    recyclable           VARCHAR(10),
    low_fat              VARCHAR(10)
);

UPDATE Products
SET recyclable =
    CASE 
        WHEN recyclable = '1' THEN 1
        ELSE 0
    END,
    low_fat =
    CASE 
        WHEN low_fat = '1' THEN 1
        ELSE 0
    END;

ALTER TABLE dbo.Products
ADD CONSTRAINT chk_price_positive
CHECK (product_retail_price >= 0 AND product_cost >= 0);


-------------------------------------------------------------------------

-- Customers Dimension
CREATE TABLE Customers(
    customer_id                 INTEGER PRIMARY KEY,     
    customer_name               VARCHAR(255) NOT NULL,  
    gender                      CHAR(1) NOT NULL,       
    age_groups                  VARCHAR(50),
    sum_of_age                  INTEGER,
    education                   VARCHAR(100),
    occupation                  VARCHAR(100),
    customer_status             VARCHAR(100),
    homeowner                   CHAR(1),               
    sum_of_income_usd           DECIMAL(15,2),
    yearly_income_bracket       VARCHAR(50),             
    marital_status              CHAR(1),               
    member_card                 VARCHAR(50),
    sum_of_num_children_at_home INTEGER,
    sum_of_total_children       INTEGER,
    sum_of_tenure_years         INTEGER,
    customer_country            VARCHAR(100),
    customer_state_province     VARCHAR(100),
    customer_city               VARCHAR(100),
    year                        INTEGER,
    quarter                     VARCHAR(10),
    month                       VARCHAR(15),
    day                         INTEGER,
    CONSTRAINT chk_gender         CHECK (gender IN ('M','F')),
    CONSTRAINT chk_marital_status CHECK (marital_status IN ('S','M','D')),
    CONSTRAINT chk_homeowner      CHECK (homeowner IN ('Y','N'))
);

-------------------------------------------------------------------------
-- Sales Fact Table
CREATE TABLE Sales (
    transaction_date DATE NOT NULL,
    stock_date       DATE NOT NULL,
    product_id       INT NOT NULL,
    customer_id      INT NOT NULL,  
    store_id         INT NOT NULL,
    quantity         INT NOT NULL,

    CONSTRAINT fk_sales_calendar
        FOREIGN KEY (transaction_date)
        REFERENCES Calendar(date),   

    CONSTRAINT fk_sales_product
        FOREIGN KEY (product_id)
        REFERENCES Products(product_id),

    CONSTRAINT fk_sales_customer
        FOREIGN KEY (customer_id)
        REFERENCES Customers(customer_id),

    CONSTRAINT fk_sales_store
        FOREIGN KEY (store_id)
        REFERENCES Stores(store_id)
);
-------------------------------------------------------------------------------------

--Returns Fact Table
CREATE TABLE returns (
    return_id INT IDENTITY(1,1) PRIMARY KEY,

    return_date DATE NOT NULL,
    product_id  INT NOT NULL,
    store_id    INT NOT NULL,
    quantity    INT NOT NULL CHECK (quantity > 0),

    CONSTRAINT fk_returns_date
        FOREIGN KEY (return_date)
        REFERENCES Calendar(date),

    CONSTRAINT fk_returns_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id),

    CONSTRAINT fk_returns_store
        FOREIGN KEY (store_id)
        REFERENCES stores(store_id)
);

-----------------------------------------------------------------------------
 --Indexes for Performance
CREATE INDEX idx_sales_product ON sales(product_id);
CREATE INDEX idx_sales_customer ON sales(customer_id);
CREATE INDEX idx_sales_store ON sales(store_id);

CREATE INDEX idx_returns_product ON returns(product_id);
CREATE INDEX idx_returns_store ON returns(store_id);

------------------------------------------------------------------------------
                        -- validation
-- Check NULLs
SELECT
    SUM(CASE WHEN transaction_date IS NULL THEN 1 ELSE 0 END) AS Null_Transaction_Date,
    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END) AS Null_Customer,
    SUM(CASE WHEN product_id IS NULL THEN 1 ELSE 0 END) AS Null_Product,
    SUM(CASE WHEN store_id IS NULL THEN 1 ELSE 0 END) AS Null_Store,
    SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END) AS Null_Quantity
FROM Sales;

-- Remove rows with NULL foreign keys
DELETE FROM Sales
WHERE transaction_date IS NULL
   OR customer_id IS NULL
   OR product_id IS NULL
   OR store_id IS NULL;

--Correct negative quantities
UPDATE Sales
SET quantity = ABS(quantity)
WHERE quantity < 0;

--Remove zero quantities
DELETE FROM Sales
WHERE quantity = 0;

-- Remove duplicates
WITH Duplicates AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY transaction_date, customer_id, product_id, store_id
               ORDER BY transaction_date
           ) AS rn
    FROM Sales
)
DELETE FROM Duplicates
WHERE rn > 1;

--Remove orphaned foreign keys
DELETE s
FROM Sales s
LEFT JOIN Products p ON s.product_id = p.product_id
WHERE p.product_id IS NULL;

DELETE s
FROM Sales s
LEFT JOIN Customers c ON s.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

DELETE s
FROM Sales s
LEFT JOIN Stores st ON s.store_id = st.store_id
WHERE st.store_id IS NULL;

--Standardize text fields
UPDATE Products
SET product_brand = UPPER(LTRIM(RTRIM(product_brand)));

UPDATE Stores
SET store_type = UPPER(LTRIM(RTRIM(store_type)));

----------------------------------------------------------------------------------
                     -- summary
-- Total transactions and counts
SELECT 
    COUNT(*) AS total_transactions,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT customer_id) AS unique_customers,
    COUNT(DISTINCT product_id) AS unique_products,
    COUNT(DISTINCT store_id) AS unique_stores
FROM Sales;

-- Top 5 transactions
SELECT TOP 5 * 
FROM Sales;

-- Transaction distribution by year
SELECT 
    YEAR(transaction_date) AS year,
    COUNT(*) AS transaction_count,
    SUM(quantity) AS total_quantity,
    COUNT(DISTINCT customer_id) AS unique_customers
FROM Sales
GROUP BY YEAR(transaction_date)
ORDER BY year DESC;

--------------------------------------------------------------------------------
-- Monthly analysis
SELECT
    YEAR(Transaction_Date) AS [Year],
    MONTH(Transaction_Date) AS [Month],
    COUNT(*) AS Transaction_Count,
    SUM(Quantity) AS Total_Quantity
FROM Sales
GROUP BY YEAR(Transaction_Date), MONTH(Transaction_Date)
ORDER BY [Year] DESC, [Month] DESC;

-- Quarterly analysis
SELECT
    YEAR(Transaction_Date) AS [Year],
    CASE
        WHEN MONTH(Transaction_Date) BETWEEN 1 AND 3 THEN 'Q1'
        WHEN MONTH(Transaction_Date) BETWEEN 4 AND 6 THEN 'Q2'
        WHEN MONTH(Transaction_Date) BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS Quarter,
    COUNT(*) AS Transaction_Count,
    SUM(Quantity) AS Total_Quantity
FROM Sales
GROUP BY
    YEAR(Transaction_Date),
    CASE
        WHEN MONTH(Transaction_Date) BETWEEN 1 AND 3 THEN 'Q1'
        WHEN MONTH(Transaction_Date) BETWEEN 4 AND 6 THEN 'Q2'
        WHEN MONTH(Transaction_Date) BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END
ORDER BY [Year] DESC, Quarter;

-- Growth month-over-month
WITH MonthlySales AS (
    SELECT 
        YEAR(transaction_date) AS SalesYear,
        MONTH(transaction_date) AS SalesMonth,
        SUM(quantity) AS TotalUnits
    FROM Sales
    GROUP BY YEAR(transaction_date), MONTH(transaction_date)
)
SELECT 
    SalesYear,
    SalesMonth,
    TotalUnits,
    LAG(TotalUnits) OVER (ORDER BY SalesYear, SalesMonth) AS PreviousMonthUnits,
    CAST(
        (TotalUnits - LAG(TotalUnits) OVER (ORDER BY SalesYear, SalesMonth)) * 100.0 /
        NULLIF(LAG(TotalUnits) OVER (ORDER BY SalesYear, SalesMonth),0)
    AS DECIMAL(10,2)) AS Growth_Percentage
FROM MonthlySales;

--------------------------------------------------------------------------------------

-- Customer segmentation
SELECT
    CASE
        WHEN COUNT(*) >= 50 THEN 'Very Active'
        WHEN COUNT(*) >= 20 THEN 'Active'
        WHEN COUNT(*) >= 5 THEN 'Occasional'
        ELSE 'Rare'
    END AS Customer_Segment,
    COUNT(*) AS Customers
FROM (
    SELECT Customer_Id, COUNT(*) AS Cnt
    FROM Sales
    GROUP BY Customer_Id
) x
GROUP BY
    CASE
        WHEN Cnt >= 50 THEN 'Very Active'
        WHEN Cnt >= 20 THEN 'Active'
        WHEN Cnt >= 5 THEN 'Occasional'
        ELSE 'Rare'
    END;

-- RFM Analysis
WITH CustomerMetrics AS (
    SELECT 
        customer_id,
        DATEDIFF(DAY, MAX(transaction_date), 
            (SELECT MAX(transaction_date) FROM Sales)) AS Recency,
        COUNT(*) AS Frequency,
        SUM(quantity) AS Monetary
    FROM Sales
    GROUP BY customer_id
)
SELECT 
    customer_id,
    Recency,
    Frequency,
    Monetary,
    NTILE(4) OVER (ORDER BY Recency ASC) AS R_Score,
    NTILE(4) OVER (ORDER BY Frequency DESC) AS F_Score,
    NTILE(4) OVER (ORDER BY Monetary DESC) AS M_Score
FROM CustomerMetrics
ORDER BY Frequency DESC;

-------------------------------------------------------------------------------------

-- Top selling products
SELECT TOP 20
    Product_Id,
    SUM(Quantity) AS Total_Quantity,
    COUNT(*) AS Transactions
FROM Sales
GROUP BY Product_Id
ORDER BY Total_Quantity DESC;

-- Bottom selling products
SELECT TOP 10
    Product_Id,
    SUM(Quantity) AS Total_Quantity
FROM Sales
GROUP BY Product_Id
ORDER BY Total_Quantity ASC;

-- Low Fat vs Regular
SELECT 
    CASE 
        WHEN p.low_fat = '1' THEN 'Low Fat'
        ELSE 'Regular'
    END AS Product_Type,
    SUM(s.quantity) AS Total_Units_Sold,
    COUNT(DISTINCT s.product_id) AS Product_Count
FROM Sales s
JOIN Products p ON s.product_id = p.product_id
GROUP BY 
    CASE 
        WHEN p.low_fat = '1' THEN 'Low Fat'
        ELSE 'Regular'
    END;

-- Profit by brand
SELECT 
    p.product_brand,
    SUM(s.quantity * p.product_retail_price) AS Total_Revenue,
    SUM(s.quantity * p.product_cost) AS Total_Cost,
    SUM(s.quantity * (p.product_retail_price - p.product_cost)) AS Total_Profit,
    CAST(
        SUM(s.quantity * (p.product_retail_price - p.product_cost)) * 100.0 /
        NULLIF(SUM(s.quantity * p.product_retail_price),0)
    AS DECIMAL(10,2)) AS Profit_Margin_Percentage
FROM Sales s
JOIN Products p ON s.product_id = p.product_id
GROUP BY p.product_brand
ORDER BY Total_Profit DESC;

-- Return Rate
SELECT 
    p.product_brand,
    SUM(s.quantity) AS Total_Sold,
    SUM(ISNULL(ret.Total_Returned,0)) AS Total_Returned,
    CAST(
        SUM(ISNULL(ret.Total_Returned,0)) * 100.0 /
        NULLIF(SUM(s.quantity),0)
    AS DECIMAL(10,2)) AS Return_Rate_Percentage
FROM Sales s
JOIN Products p ON s.product_id = p.product_id
LEFT JOIN (
    SELECT product_id, SUM(quantity) AS Total_Returned
    FROM Returns
    GROUP BY product_id
) ret ON s.product_id = ret.product_id
GROUP BY p.product_brand
HAVING SUM(s.quantity) > 100
ORDER BY Return_Rate_Percentage DESC;
-------------------------------------------------------------------------------------------
-- Store performance
SELECT
    Store_Id,
    SUM(Quantity) AS Total_Units,
    COUNT(*) AS Transactions,
    COUNT(DISTINCT Customer_Id) AS Unique_Customers
FROM Sales
GROUP BY Store_Id
ORDER BY Total_Units DESC;

-- Store Profit per Sqft
SELECT 
    st.store_name,
    st.total_sqft,
    SUM(s.quantity * (p.product_retail_price - p.product_cost)) AS Total_Profit,
    CAST(
        SUM(s.quantity * (p.product_retail_price - p.product_cost)) * 1.0 /
        NULLIF(st.total_sqft,0)
    AS DECIMAL(10,2)) AS Profit_per_Sqft
FROM Sales s
JOIN Stores st ON s.store_id = st.store_id
JOIN Products p ON s.product_id = p.product_id
GROUP BY st.store_name, st.total_sqft
ORDER BY Profit_per_Sqft DESC;

-- Regional top brand
WITH RegionalBrandSales AS (
    SELECT 
        r.sales_region,
        p.product_brand,
        SUM(s.quantity) AS TotalUnits,
        ROW_NUMBER() OVER (
            PARTITION BY r.sales_region 
            ORDER BY SUM(s.quantity) DESC
        ) AS Rank
    FROM Sales s
    JOIN Stores st ON s.store_id = st.store_id
    JOIN Region r ON st.region_id = r.region_id
    JOIN Products p ON s.product_id = p.product_id
    GROUP BY r.sales_region, p.product_brand
)
SELECT sales_region, product_brand, TotalUnits
FROM RegionalBrandSales
WHERE Rank = 1;
-----------------------------------------------------------------------------

SELECT TOP 30
    s1.Product_Id AS Product_1,
    s2.Product_Id AS Product_2,
    COUNT(*) AS Co_Purchase_Count
FROM Sales s1
JOIN Sales s2
    ON s1.Customer_Id = s2.Customer_Id
    AND s1.Transaction_Date = s2.Transaction_Date
    AND s1.Product_Id < s2.Product_Id
GROUP BY s1.Product_Id, s2.Product_Id
ORDER BY Co_Purchase_Count DESC;
--------------------------------------------------------------------------------
--Top 3 Customers Per Year (CTE + Window Function)
WITH CustomerYearly AS (
    SELECT 
        YEAR(transaction_date) AS SalesYear,
        customer_id,
        SUM(quantity) AS TotalUnits
    FROM Sales
    GROUP BY YEAR(transaction_date), customer_id
)

SELECT *
FROM (
    SELECT *,
           DENSE_RANK() OVER (PARTITION BY SalesYear ORDER BY TotalUnits DESC) AS Rank_Per_Year
    FROM CustomerYearly
) x
WHERE Rank_Per_Year <= 3
ORDER BY SalesYear DESC, TotalUnits DESC;
----------------------------------------------------------------------------------
--Product Contribution % of Total Sales (Window function)
SELECT 
    product_id,
    SUM(quantity) AS TotalUnits,
    CAST(
        SUM(quantity) * 100.0 /
        SUM(SUM(quantity)) OVER ()
    AS DECIMAL(10,2)) AS Contribution_Percentage
FROM Sales
GROUP BY product_id
ORDER BY Contribution_Percentage DESC;
---------------------------------------------------------------------------------
--Running Total (Cumulative Sales Over Time)
SELECT
    transaction_date,
    SUM(quantity) AS Daily_Sales,
    SUM(SUM(quantity)) OVER (
        ORDER BY transaction_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS Running_Total
FROM Sales
GROUP BY transaction_date
ORDER BY transaction_date;
--------------------------------------------------------------------------
--Moving Average (3-Month Rolling Average)
WITH MonthlySales AS (
    SELECT 
        YEAR(transaction_date) AS SalesYear,
        MONTH(transaction_date) AS SalesMonth,
        SUM(quantity) AS TotalUnits
    FROM Sales
    GROUP BY YEAR(transaction_date), MONTH(transaction_date)
)

SELECT *,
       AVG(TotalUnits) OVER (
           ORDER BY SalesYear, SalesMonth
           ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
       ) AS Moving_Avg_3Months
FROM MonthlySales;
------------------------------------------------------------------------
--Customers Above Average Spending (Subquery)
SELECT customer_id,
       SUM(quantity) AS TotalUnits
FROM Sales
GROUP BY customer_id
HAVING SUM(quantity) >
       (SELECT AVG(TotalQty)
        FROM (
            SELECT SUM(quantity) AS TotalQty
            FROM Sales
            GROUP BY customer_id
        ) x);

    -----------------------------------------------------------------------------------
--Best Product Per Store (CTE + ROW_NUMBER)
 WITH StoreProduct AS (
    SELECT 
        store_id,
        product_id,
        SUM(quantity) AS TotalUnits,
        ROW_NUMBER() OVER (
            PARTITION BY store_id
            ORDER BY SUM(quantity) DESC
        ) AS Rank_Per_Store
    FROM Sales
    GROUP BY store_id, product_id
)

SELECT *
FROM StoreProduct
WHERE Rank_Per_Store = 1;
-------------------------------------------------------------------------
--Revenue Share Per Brand Inside Region (Window Function)
WITH BrandRegionRevenue AS (
    SELECT 
        r.sales_region,
        p.product_brand,
        SUM(s.quantity * p.product_retail_price) AS Revenue
    FROM Sales s
    JOIN Products p ON s.product_id = p.product_id
    JOIN Stores st ON s.store_id = st.store_id
    JOIN Region r ON st.region_id = r.region_id
    GROUP BY r.sales_region, p.product_brand
)

SELECT *,
       CAST(
           Revenue * 100.0 /
           SUM(Revenue) OVER (PARTITION BY sales_region)
       AS DECIMAL(10,2)) AS Region_Share_Percentage
FROM BrandRegionRevenue
ORDER BY sales_region, Revenue DESC;
-----------------------------------------------------------------------
--Customer Retention (Customers who bought in consecutive months)
WITH CustomerMonths AS (
    SELECT DISTINCT
        customer_id,
        YEAR(transaction_date) AS Y,
        MONTH(transaction_date) AS M
    FROM Sales
)

SELECT COUNT(DISTINCT c1.customer_id) AS Retained_Customers
FROM CustomerMonths c1
JOIN CustomerMonths c2
    ON c1.customer_id = c2.customer_id
    AND DATEADD(MONTH, 1, DATEFROMPARTS(c1.Y, c1.M, 1)) =
        DATEFROMPARTS(c2.Y, c2.M, 1);
---------------------------------------------------------------------------------
--Detect Sales Outliers (Window Function)
WITH ProductStats AS (
    SELECT 
        product_id,
        quantity,
        AVG(quantity) OVER (PARTITION BY product_id) AS Avg_Qty,
        STDEV(quantity) OVER (PARTITION BY product_id) AS Std_Qty
    FROM Sales
)

SELECT *
FROM ProductStats
WHERE quantity > Avg_Qty + (2 * Std_Qty);

----------------------------------------------------------------------------------
--view
IF OBJECT_ID('vw_DailySales', 'V') IS NOT NULL
    DROP VIEW vw_DailySales;
GO
CREATE VIEW vw_DailySales AS
SELECT 
    s.transaction_date,
    c.day_number,
    c.day_name,
    c.week_number,
    c.month_number,
    c.month_name,
    c.quarter_number,
    c.year_number,

    s.store_id,
    st.store_name,
    st.store_type,
    r.sales_region,

    s.product_id,
    p.product_name,
    p.product_brand,

    s.customer_id,
    cu.customer_name,

    s.quantity,
    (s.quantity * p.product_retail_price) AS Revenue,
    (s.quantity * (p.product_retail_price - p.product_cost)) AS Profit

FROM Sales s
JOIN Calendar c   ON s.transaction_date = c.date
JOIN Stores st    ON s.store_id = st.store_id
JOIN Region r     ON st.region_id = r.region_id
JOIN Products p   ON s.product_id = p.product_id
JOIN Customers cu ON s.customer_id = cu.customer_id;
GO

-------------------------------------------------------------------
CREATE OR ALTER VIEW vw_MonthlySales AS
SELECT
    year_number AS SalesYear,
    month_number AS SalesMonth,
    CONCAT(year_number, '-', RIGHT('0' + CAST(month_number AS VARCHAR),2)) AS YearMonth,
    SUM(quantity) AS TotalUnits,
    SUM(Revenue) AS TotalRevenue,
    SUM(Profit) AS TotalProfit
FROM vw_DailySales
GROUP BY year_number, month_number;
GO

------------------------------------------------------------------------
CREATE OR ALTER VIEW vw_CustomerSummary AS
SELECT
    c.customer_id,
    c.customer_name,
    c.gender,
    c.age_groups AS age_group,                  
    c.sum_of_age AS age,                        
    c.education,
    c.occupation,
    c.customer_status,
    c.homeowner,
    c.marital_status,
    c.member_card,
    c.sum_of_num_children_at_home AS num_children_at_home, 
    c.sum_of_total_children AS total_children,             
    c.sum_of_tenure_years AS tenure_years,                
    COUNT(s.transaction_date) AS TotalTransactions,
    SUM(s.quantity) AS TotalUnitsPurchased,
    SUM(s.quantity * p.product_retail_price) AS TotalRevenue,
    SUM(s.quantity * (p.product_retail_price - p.product_cost)) AS TotalProfit,
    c.yearly_income AS yearly_income_range       
FROM Sales s
JOIN Customers c
    ON s.customer_id = c.customer_id
JOIN Products p
    ON s.product_id = p.product_id
GROUP BY 
    c.customer_id, c.customer_name, c.gender, c.age_groups, c.sum_of_age, c.education, 
    c.occupation, c.customer_status, c.homeowner, 
    c.marital_status, c.member_card, c.sum_of_num_children_at_home, c.sum_of_total_children, 
    c.sum_of_tenure_years, c.yearly_income;

--------------------------------------------------------------------------
CREATE OR ALTER VIEW vw_ProductSummary AS
SELECT
    product_id,
    product_name,
    product_brand,
    SUM(quantity) AS TotalUnitsSold,
    SUM(Revenue) AS TotalRevenue,
    SUM(Profit) AS TotalProfit,
    CAST(
        SUM(Profit) * 100.0 /
        NULLIF(SUM(Revenue),0)
    AS DECIMAL(10,2)) AS ProfitMarginPercentage
FROM vw_DailySales
GROUP BY product_id, product_name, product_brand;
GO

---------------------------------------------------------------------------
CREATE OR ALTER VIEW vw_StorePerformance AS
SELECT
    d.store_id,
    d.store_name,
    d.store_type,
    d.sales_region,
    st.total_sqft,
    SUM(d.quantity) AS TotalUnitsSold,
    SUM(d.Revenue) AS TotalRevenue,
    SUM(d.Profit) AS TotalProfit,
    CAST(
        SUM(d.Profit) * 1.0 / NULLIF(st.total_sqft,0)
    AS DECIMAL(10,2)) AS ProfitPerSqft
FROM vw_DailySales d
JOIN Stores st ON d.store_id = st.store_id
GROUP BY
    d.store_id,
    d.store_name,
    d.store_type,
    d.sales_region,
    st.total_sqft;
GO

-----------------------------------------------------------------------------
CREATE OR ALTER VIEW vw_ReturnsSummary AS
SELECT
    r.return_date,
    c.year_number,
    c.month_number,
    r.store_id,
    st.store_name,
    r.product_id,
    p.product_name,
    p.product_brand,
    SUM(r.quantity) AS ReturnedUnits,
    SUM(r.quantity * p.product_retail_price) AS ReturnedRevenue
FROM Returns r
JOIN Calendar c ON r.return_date = c.date
JOIN Products p ON r.product_id = p.product_id
JOIN Stores st ON r.store_id = st.store_id
GROUP BY
    r.return_date,
    c.year_number,
    c.month_number,
    r.store_id,
    st.store_name,
    r.product_id,
    p.product_name,
    p.product_brand;
GO

----------------------------------------------------------------------
CREATE OR ALTER VIEW vw_ProductReturnRate AS
WITH SalesAgg AS (
    SELECT product_id, SUM(quantity) AS TotalSold
    FROM Sales
    GROUP BY product_id
),
ReturnAgg AS (
    SELECT product_id, SUM(quantity) AS TotalReturned
    FROM Returns
    GROUP BY product_id
)
SELECT
    p.product_id,
    p.product_name,
    p.product_brand,
    s.TotalSold,
    ISNULL(r.TotalReturned,0) AS TotalReturned,
    CAST(
        ISNULL(r.TotalReturned,0) * 100.0 /
        NULLIF(s.TotalSold,0)
    AS DECIMAL(10,2)) AS ReturnRatePercentage
FROM SalesAgg s
LEFT JOIN ReturnAgg r ON s.product_id = r.product_id
JOIN Products p ON s.product_id = p.product_id
WHERE s.TotalSold > 100;
GO