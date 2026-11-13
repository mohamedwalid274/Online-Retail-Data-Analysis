
-- ============================================================
-- ONLINE RETAIL DATA ANALYSIS PROJECT
-- 25 SQL BUSINESS ANALYSIS QUESTIONS & ANSWERS
-- Table: dbo.online_retail
-- ============================================================


-- Q1: What is the SQL Server name?

SELECT @@SERVERNAME AS ServerName;


-- Q2: What is the total number of records in the dataset?

SELECT COUNT(*) AS Total_Rows
FROM dbo.online_retail;


-- Q3: What is the date range of the dataset?

SELECT
    MIN(TRY_CONVERT(DATETIME2, InvoiceDate, 120)) AS First_Invoice_Date,
    MAX(TRY_CONVERT(DATETIME2, InvoiceDate, 120)) AS Last_Invoice_Date
FROM dbo.online_retail;


-- Q4: How many unique customers are in the dataset?

SELECT COUNT(DISTINCT CustomerID) AS Unique_Customers
FROM dbo.online_retail;


-- Q5: How many unique countries are represented in the dataset?

SELECT COUNT(DISTINCT Country) AS Unique_Countries
FROM dbo.online_retail;


-- Q6: How many records have missing CustomerID values?

SELECT COUNT(*) AS Missing_CustomerID
FROM dbo.online_retail
WHERE CustomerID IS NULL;


-- Q7: What is the percentage of missing CustomerID values?

SELECT
    COUNT(*) AS Total_Rows,
    SUM(CASE
        WHEN CustomerID IS NULL THEN 1
        ELSE 0
    END) AS Missing_CustomerID,
    CAST(
        100.0 * SUM(CASE
            WHEN CustomerID IS NULL THEN 1
            ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS Missing_Percentage
FROM dbo.online_retail;


-- Q8: How many unique invoices are in the dataset?

SELECT COUNT(DISTINCT InvoiceNo) AS Unique_Invoices
FROM dbo.online_retail;


-- Q9: What is the average invoice value?

WITH InvoiceTotals AS (
    SELECT
        InvoiceNo,
        SUM(Quantity * UnitPrice) AS InvoiceValue
    FROM dbo.online_retail
    WHERE InvoiceNo NOT LIKE 'C%'
      AND InvoiceNo IS NOT NULL
    GROUP BY InvoiceNo
)
SELECT
    AVG(InvoiceValue) AS Average_Invoice_Value
FROM InvoiceTotals;


-- Q10: What is the total revenue for each month?

SELECT
    YEAR(TRY_CONVERT(DATETIME2, InvoiceDate)) AS Sales_Year,
    MONTH(TRY_CONVERT(DATETIME2, InvoiceDate)) AS Sales_Month,
    SUM(Quantity * UnitPrice) AS Monthly_Revenue
FROM dbo.online_retail
WHERE Quantity > 0
  AND UnitPrice > 0
  AND InvoiceNo NOT LIKE 'C%'
GROUP BY
    YEAR(TRY_CONVERT(DATETIME2, InvoiceDate)),
    MONTH(TRY_CONVERT(DATETIME2, InvoiceDate))
ORDER BY Sales_Year, Sales_Month;


-- Q11: What is the month-over-month revenue growth?

WITH MonthlySales AS (
    SELECT
        DATEFROMPARTS(
            YEAR(TRY_CONVERT(DATETIME2, InvoiceDate)),
            MONTH(TRY_CONVERT(DATETIME2, InvoiceDate)),
            1
        ) AS Sales_Month,
        SUM(Quantity * UnitPrice) AS Monthly_Revenue
    FROM dbo.online_retail
    WHERE Quantity > 0
      AND UnitPrice > 0
      AND InvoiceNo NOT LIKE 'C%'
    GROUP BY
        YEAR(TRY_CONVERT(DATETIME2, InvoiceDate)),
        MONTH(TRY_CONVERT(DATETIME2, InvoiceDate))
),
SalesWithPreviousMonth AS (
    SELECT
        Sales_Month,
        Monthly_Revenue,
        LAG(Monthly_Revenue) OVER (
            ORDER BY Sales_Month
        ) AS Previous_Month_Revenue
    FROM MonthlySales
)
SELECT
    Sales_Month,
    Monthly_Revenue,
    Previous_Month_Revenue,
    CAST(
        (Monthly_Revenue - Previous_Month_Revenue)
        * 100.0 / NULLIF(Previous_Month_Revenue, 0)
        AS DECIMAL(10,2)
    ) AS Growth_Percentage
FROM SalesWithPreviousMonth
ORDER BY Sales_Month;


-- Q12: What are the top 10 products by revenue?

SELECT TOP 10
    StockCode,
    Description,
    SUM(Quantity * UnitPrice) AS Total_Revenue
FROM dbo.online_retail
WHERE Quantity > 0
  AND UnitPrice > 0
  AND InvoiceNo NOT LIKE 'C%'
GROUP BY StockCode, Description
ORDER BY Total_Revenue DESC;


-- Q13: Which products have the lowest sales performance?

-- Considering products with at least 100 sales transactions.

SELECT
    StockCode,
    Description,
    COUNT(DISTINCT InvoiceNo) AS Total_Transactions,
    SUM(Quantity) AS Total_Quantity,
    SUM(Quantity * UnitPrice) AS Total_Revenue
FROM dbo.online_retail
WHERE Quantity > 0
  AND UnitPrice > 0
  AND InvoiceNo NOT LIKE 'C%'
GROUP BY StockCode, Description
HAVING COUNT(DISTINCT InvoiceNo) >= 100
ORDER BY Total_Revenue ASC;


-- Q14: Which products have the highest returned quantities?

SELECT
    StockCode,
    Description,
    SUM(ABS(Quantity)) AS Returned_Quantity
FROM dbo.online_retail
WHERE Quantity < 0
GROUP BY StockCode, Description
ORDER BY Returned_Quantity DESC;


-- Q15: What percentage of total revenue does each product contribute?

WITH ProductRevenue AS (
    SELECT
        StockCode,
        Description,
        SUM(Quantity * UnitPrice) AS Total_Revenue
    FROM dbo.online_retail
    WHERE Quantity > 0
      AND UnitPrice > 0
      AND InvoiceNo NOT LIKE 'C%'
    GROUP BY StockCode, Description
)
SELECT
    StockCode,
    Description,
    Total_Revenue,
    CAST(
        Total_Revenue * 100.0 /
        NULLIF(SUM(Total_Revenue) OVER (), 0)
        AS DECIMAL(10,2)
    ) AS Revenue_Contribution_Percentage
FROM ProductRevenue
ORDER BY Total_Revenue DESC;


-- Q16: Who are the top 10 customers by total spending?

SELECT TOP 10
    CustomerID,
    SUM(Quantity * UnitPrice) AS Total_Spending,
    COUNT(DISTINCT InvoiceNo) AS Total_Orders
FROM dbo.online_retail
WHERE CustomerID IS NOT NULL
  AND Quantity > 0
  AND UnitPrice > 0
  AND InvoiceNo NOT LIKE 'C%'
GROUP BY CustomerID
ORDER BY Total_Spending DESC;


-- Q17: What percentage of customers are repeat customers?

WITH CustomerOrders AS (
    SELECT
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS Order_Count
    FROM dbo.online_retail
    WHERE CustomerID IS NOT NULL
      AND Quantity > 0
      AND UnitPrice > 0
      AND InvoiceNo NOT LIKE 'C%'
    GROUP BY CustomerID
)
SELECT
    COUNT(*) AS Total_Customers,
    SUM(CASE WHEN Order_Count > 1 THEN 1 ELSE 0 END)
        AS Repeat_Customers,
    CAST(
        100.0 * SUM(
            CASE WHEN Order_Count > 1 THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS Repeat_Customer_Percentage
FROM CustomerOrders;


-- Q18: What is the average spending per customer compared
-- with the average invoice value?

WITH CustomerSpending AS (
    SELECT
        CustomerID,
        SUM(Quantity * UnitPrice) AS Total_Spending
    FROM dbo.online_retail
    WHERE CustomerID IS NOT NULL
      AND Quantity > 0
      AND UnitPrice > 0
      AND InvoiceNo NOT LIKE 'C%'
    GROUP BY CustomerID
),
InvoiceTotals AS (
    SELECT
        InvoiceNo,
        SUM(Quantity * UnitPrice) AS InvoiceValue
    FROM dbo.online_retail
    WHERE Quantity > 0
      AND UnitPrice > 0
      AND InvoiceNo NOT LIKE 'C%'
    GROUP BY InvoiceNo
)
SELECT
    (SELECT AVG(Total_Spending)
     FROM CustomerSpending) AS Average_Customer_Spending,
    (SELECT AVG(InvoiceValue)
     FROM InvoiceTotals) AS Average_Invoice_Value;


-- Q19: What are the top 10 countries by revenue?

SELECT TOP 10
    Country,
    SUM(Quantity * UnitPrice) AS Total_Revenue
FROM dbo.online_retail
WHERE Quantity > 0
  AND UnitPrice > 0
  AND InvoiceNo NOT LIKE 'C%'
GROUP BY Country
ORDER BY Total_Revenue DESC;


-- Q20: How do countries compare in revenue, orders,
-- customers, and average order value?

SELECT
    Country,
    SUM(Quantity * UnitPrice) AS Total_Revenue,
    COUNT(DISTINCT InvoiceNo) AS Total_Orders,
    COUNT(DISTINCT CustomerID) AS Total_Customers,
    CAST(
        SUM(Quantity * UnitPrice) /
        NULLIF(COUNT(DISTINCT InvoiceNo) * 1.0, 0)
        AS DECIMAL(10,2)
    ) AS Average_Order_Value
FROM dbo.online_retail
WHERE Quantity > 0
  AND UnitPrice > 0
  AND InvoiceNo NOT LIKE 'C%'
GROUP BY Country
ORDER BY Total_Revenue DESC;


-- Q21: Which days of the week generate the highest revenue?

SELECT
    DATENAME(
        WEEKDAY,
        TRY_CONVERT(DATETIME2, InvoiceDate)
    ) AS Weekday_Name,
    SUM(Quantity * UnitPrice) AS Total_Revenue
FROM dbo.online_retail
WHERE Quantity > 0
  AND UnitPrice > 0
  AND InvoiceNo NOT LIKE 'C%'
  AND TRY_CONVERT(DATETIME2, InvoiceDate) IS NOT NULL
GROUP BY
    DATENAME(
        WEEKDAY,
        TRY_CONVERT(DATETIME2, InvoiceDate)
    ),
    DATEPART(
        WEEKDAY,
        TRY_CONVERT(DATETIME2, InvoiceDate)
    )
ORDER BY
    DATEPART(
        WEEKDAY,
        TRY_CONVERT(DATETIME2, InvoiceDate)
    );


-- Q22: Which months show the highest seasonal revenue?

SELECT
    MONTH(TRY_CONVERT(DATETIME2, InvoiceDate)) AS Month_Number,
    DATENAME(
        MONTH,
        TRY_CONVERT(DATETIME2, InvoiceDate)
    ) AS Month_Name,
    SUM(Quantity * UnitPrice) AS Total_Revenue
FROM dbo.online_retail
WHERE Quantity > 0
  AND UnitPrice > 0
  AND InvoiceNo NOT LIKE 'C%'
  AND TRY_CONVERT(DATETIME2, InvoiceDate) IS NOT NULL
GROUP BY
    MONTH(TRY_CONVERT(DATETIME2, InvoiceDate)),
    DATENAME(
        MONTH,
        TRY_CONVERT(DATETIME2, InvoiceDate)
    )
ORDER BY Total_Revenue DESC;


-- Q23: How can customers be divided into spending tiers?

WITH CustomerSpending AS (
    SELECT
        CustomerID,
        SUM(Quantity * UnitPrice) AS Total_Spending
    FROM dbo.online_retail
    WHERE CustomerID IS NOT NULL
      AND Quantity > 0
      AND UnitPrice > 0
      AND InvoiceNo NOT LIKE 'C%'
    GROUP BY CustomerID
),
CustomerTiers AS (
    SELECT
        CustomerID,
        Total_Spending,
        NTILE(4) OVER (
            ORDER BY Total_Spending DESC
        ) AS Spending_Tier
    FROM CustomerSpending
)
SELECT
    CASE Spending_Tier
        WHEN 1 THEN 'High Value'
        WHEN 2 THEN 'Upper Middle'
        WHEN 3 THEN 'Lower Middle'
        WHEN 4 THEN 'Low Value'
    END AS Customer_Segment,
    COUNT(*) AS Number_Of_Customers,
    AVG(Total_Spending) AS Average_Spending
FROM CustomerTiers
GROUP BY Spending_Tier
ORDER BY Spending_Tier;


-- Q24: What percentage of total revenue comes from
-- the top 10 customers?

WITH CustomerRevenue AS (
    SELECT
        CustomerID,
        SUM(Quantity * UnitPrice) AS Total_Spending
    FROM dbo.online_retail
    WHERE CustomerID IS NOT NULL
      AND Quantity > 0
      AND UnitPrice > 0
      AND InvoiceNo NOT LIKE 'C%'
    GROUP BY CustomerID
),
TopCustomers AS (
    SELECT TOP 10
        CustomerID,
        Total_Spending
    FROM CustomerRevenue
    ORDER BY Total_Spending DESC
)
SELECT
    SUM(Total_Spending) AS Top_10_Customers_Revenue,
    (SELECT SUM(Total_Spending)
     FROM CustomerRevenue) AS Total_Revenue,
    CAST(
        100.0 * SUM(Total_Spending) /
        NULLIF(
            (SELECT SUM(Total_Spending)
             FROM CustomerRevenue), 0
        )
        AS DECIMAL(10,2)
    ) AS Top_10_Revenue_Contribution_Percentage
FROM TopCustomers;


-- Q25: What is the executive sales performance summary?

SELECT
    SUM(Quantity * UnitPrice) AS Total_Revenue,
    COUNT(DISTINCT InvoiceNo) AS Total_Orders,
    COUNT(DISTINCT CustomerID) AS Total_Customers,
    SUM(Quantity) AS Total_Quantity_Sold,
    SUM(CASE
        WHEN Quantity < 0 THEN ABS(Quantity)
        ELSE 0
    END) AS Returned_Quantity,
    CAST(
        SUM(Quantity * UnitPrice) /
        NULLIF(COUNT(DISTINCT InvoiceNo) * 1.0, 0)
        AS DECIMAL(10,2)
    ) AS Average_Order_Value
FROM dbo.online_retail
WHERE InvoiceNo NOT LIKE 'C%'
  AND Quantity > 0
  AND UnitPrice > 0;


-- ============================================================
-- END OF ONLINE RETAIL SQL ANALYSIS
-- TOTAL QUESTIONS: 25
-- ============================================================

WITH SalesData AS (
    SELECT
        TRY_CONVERT(DATETIME2, InvoiceDate, 120) AS InvoiceDate,
        Quantity * UnitPrice AS Sales
    FROM dbo.online_retail
    WHERE InvoiceNo NOT LIKE 'C%'
)
SELECT
    YEAR(InvoiceDate) AS Sales_Year,
    MONTH(InvoiceDate) AS Sales_Month,
    SUM(Sales) AS Monthly_Sales
FROM SalesData
WHERE InvoiceDate IS NOT NULL
GROUP BY
    YEAR(InvoiceDate),
    MONTH(InvoiceDate)
ORDER BY
    Sales_Year,
    Sales_Month;


WITH MonthlySales AS (
    SELECT
        DATEFROMPARTS(
            YEAR(TRY_CONVERT(DATETIME2, InvoiceDate, 120)),
            MONTH(TRY_CONVERT(DATETIME2, InvoiceDate, 120)),
            1
        ) AS SalesMonth,
        SUM(Quantity * UnitPrice) AS Sales
    FROM dbo.online_retail
    WHERE InvoiceNo NOT LIKE 'C%'
      AND TRY_CONVERT(DATETIME2, InvoiceDate, 120) IS NOT NULL
    GROUP BY
        YEAR(TRY_CONVERT(DATETIME2, InvoiceDate, 120)),
        MONTH(TRY_CONVERT(DATETIME2, InvoiceDate, 120))
),
SalesComparison AS (
    SELECT
        SalesMonth,
        Sales,
        LAG(Sales) OVER (ORDER BY SalesMonth) AS Previous_Month_Sales
    FROM MonthlySales
)
SELECT
    SalesMonth,
    Sales,
    Previous_Month_Sales,
    CAST(
        100.0 * (Sales - Previous_Month_Sales)
        / NULLIF(Previous_Month_Sales, 0)
        AS DECIMAL(10,2)
    ) AS Growth_Percentage
FROM SalesComparison
ORDER BY SalesMonth;


SELECT TOP 10
    StockCode,
    MAX(Description) AS Product_Name,
    SUM(Quantity * UnitPrice) AS Revenue
FROM dbo.online_retail
WHERE InvoiceNo NOT LIKE 'C%'
  AND Quantity > 0
  AND UnitPrice > 0
GROUP BY StockCode
ORDER BY Revenue DESC;




SELECT TOP 10
    StockCode,
    MAX(Description) AS Product_Name,
    SUM(Quantity) AS Total_Quantity_Sold
FROM dbo.online_retail
WHERE InvoiceNo NOT LIKE 'C%'
  AND Quantity > 0
GROUP BY StockCode
ORDER BY Total_Quantity_Sold DESC;



SELECT
    StockCode,
    MAX(Description) AS Product_Name,
    COUNT(*) AS Transaction_Lines,
    SUM(Quantity) AS Total_Quantity_Sold,
    SUM(Quantity * UnitPrice) AS Revenue
FROM dbo.online_retail
WHERE InvoiceNo NOT LIKE 'C%'
  AND Quantity > 0
  AND UnitPrice > 0
GROUP BY StockCode
HAVING COUNT(*) >= 10
ORDER BY Revenue ASC;



SELECT TOP 10
    StockCode,
    MAX(Description) AS Product_Name,
    COUNT(*) AS Return_Lines,
    SUM(ABS(Quantity)) AS Returned_Quantity,
    SUM(ABS(Quantity * UnitPrice)) AS Return_Value
FROM dbo.online_retail
WHERE Quantity < 0
  AND InvoiceNo NOT LIKE 'C%'
GROUP BY StockCode
ORDER BY Returned_Quantity DESC;




WITH ProductSales AS (
    SELECT
        StockCode,
        MAX(Description) AS Product_Name,
        SUM(Quantity * UnitPrice) AS Revenue
    FROM dbo.online_retail
    WHERE InvoiceNo NOT LIKE 'C%'
      AND Quantity > 0
      AND UnitPrice > 0
    GROUP BY StockCode
)
SELECT
    StockCode,
    Product_Name,
    Revenue,
    CAST(
        100.0 * Revenue
        / NULLIF(SUM(Revenue) OVER (), 0)
        AS DECIMAL(10,2)
    ) AS Revenue_Share_Percentage
FROM ProductSales
ORDER BY Revenue DESC;





SELECT TOP 10
    CustomerID,
    SUM(Quantity * UnitPrice) AS Total_Spending,
    COUNT(DISTINCT InvoiceNo) AS Invoice_Count
FROM dbo.online_retail
WHERE CustomerID IS NOT NULL
  AND InvoiceNo NOT LIKE 'C%'
GROUP BY CustomerID
ORDER BY Total_Spending DESC;




WITH CustomerInvoices AS (
    SELECT
        CustomerID,
        COUNT(DISTINCT InvoiceNo) AS Invoice_Count
    FROM dbo.online_retail
    WHERE CustomerID IS NOT NULL
      AND InvoiceNo NOT LIKE 'C%'
    GROUP BY CustomerID
)
SELECT
    COUNT(*) AS Total_Customers,
    SUM(CASE
        WHEN Invoice_Count >= 2 THEN 1
        ELSE 0
    END) AS Repeat_Customers,
    CAST(
        100.0 * SUM(CASE
            WHEN Invoice_Count >= 2 THEN 1
            ELSE 0
        END) / NULLIF(COUNT(*), 0)
        AS DECIMAL(10,2)
    ) AS Repeat_Customer_Percentage
FROM CustomerInvoices;




WITH CustomerSpending AS (
    SELECT
        CustomerID,
        SUM(Quantity * UnitPrice) AS Total_Spending
    FROM dbo.online_retail
    WHERE CustomerID IS NOT NULL
      AND InvoiceNo NOT LIKE 'C%'
    GROUP BY CustomerID
),
InvoiceTotals AS (
    SELECT
        InvoiceNo,
        SUM(Quantity * UnitPrice) AS Invoice_Value
    FROM dbo.online_retail
    WHERE InvoiceNo NOT LIKE 'C%'
    GROUP BY InvoiceNo
)
SELECT
    (SELECT AVG(Total_Spending)
     FROM CustomerSpending) AS Average_Customer_Spending,
    (SELECT AVG(Invoice_Value)
     FROM InvoiceTotals) AS Average_Invoice_Value;



SELECT TOP 10
    Country,
    SUM(Quantity * UnitPrice) AS Revenue
FROM dbo.online_retail
WHERE InvoiceNo NOT LIKE 'C%'
  AND Quantity > 0
  AND UnitPrice > 0
GROUP BY Country
ORDER BY Revenue DESC;



SELECT
    Country,
    SUM(Quantity * UnitPrice) AS Revenue,
    COUNT(DISTINCT InvoiceNo) AS Invoice_Count,
    COUNT(DISTINCT CustomerID) AS Customer_Count,
    CAST(
        SUM(Quantity * UnitPrice)
        / NULLIF(COUNT(DISTINCT InvoiceNo) * 1.0, 0)
        AS DECIMAL(12,2)
    ) AS Revenue_Per_Invoice
FROM dbo.online_retail
WHERE InvoiceNo NOT LIKE 'C%'
  AND Quantity > 0
  AND UnitPrice > 0
GROUP BY Country
ORDER BY Revenue DESC;





WITH DailySales AS (
    SELECT
        CAST(
            TRY_CONVERT(DATETIME2, InvoiceDate, 120)
            AS DATE
        ) AS SalesDate,
        SUM(Quantity * UnitPrice) AS Daily_Revenue
    FROM dbo.online_retail
    WHERE InvoiceNo NOT LIKE 'C%'
      AND Quantity > 0
      AND UnitPrice > 0
      AND TRY_CONVERT(DATETIME2, InvoiceDate, 120) IS NOT NULL
    GROUP BY CAST(
        TRY_CONVERT(DATETIME2, InvoiceDate, 120)
        AS DATE
    )
)
SELECT
    DATENAME(WEEKDAY, SalesDate) AS Day_Name,
    COUNT(*) AS Days_Observed,
    AVG(Daily_Revenue) AS Average_Daily_Revenue,
    SUM(Daily_Revenue) AS Total_Revenue
FROM DailySales
GROUP BY DATEPART(WEEKDAY, SalesDate),
         DATENAME(WEEKDAY, SalesDate)
ORDER BY Average_Daily_Revenue DESC;




WITH MonthlySales AS (
    SELECT
        YEAR(TRY_CONVERT(DATETIME2, InvoiceDate, 120)) AS Sales_Year,
        MONTH(TRY_CONVERT(DATETIME2, InvoiceDate, 120)) AS Sales_Month,
        SUM(Quantity * UnitPrice) AS Revenue
    FROM dbo.online_retail
    WHERE InvoiceNo NOT LIKE 'C%'
      AND Quantity > 0
      AND UnitPrice > 0
      AND TRY_CONVERT(DATETIME2, InvoiceDate, 120) IS NOT NULL
    GROUP BY
        YEAR(TRY_CONVERT(DATETIME2, InvoiceDate, 120)),
        MONTH(TRY_CONVERT(DATETIME2, InvoiceDate, 120))
)
SELECT
    Sales_Month,
    COUNT(*) AS Years_Observed,
    AVG(Revenue) AS Average_Monthly_Revenue,
    SUM(Revenue) AS Total_Revenue
FROM MonthlySales
GROUP BY Sales_Month
ORDER BY Sales_Month;




WITH CustomerSpending AS (
    SELECT
        CustomerID,
        SUM(Quantity * UnitPrice) AS Total_Spending
    FROM dbo.online_retail
    WHERE CustomerID IS NOT NULL
      AND InvoiceNo NOT LIKE 'C%'
    GROUP BY CustomerID
),
CustomerSegments AS (
    SELECT
        CustomerID,
        Total_Spending,
        NTILE(4) OVER (
            ORDER BY Total_Spending DESC
        ) AS Spending_Quartile
    FROM CustomerSpending
)
SELECT
    CustomerID,
    Total_Spending,
    Spending_Quartile,
    CASE Spending_Quartile
        WHEN 1 THEN 'High Spending'
        WHEN 2 THEN 'Upper-Middle Spending'
        WHEN 3 THEN 'Lower-Middle Spending'
        WHEN 4 THEN 'Low Spending'
    END AS Customer_Segment
FROM CustomerSegments
ORDER BY Total_Spending DESC;





WITH CustomerSpending AS (
    SELECT
        CustomerID,
        SUM(Quantity * UnitPrice) AS Total_Spending
    FROM dbo.online_retail
    WHERE CustomerID IS NOT NULL
      AND InvoiceNo NOT LIKE 'C%'
    GROUP BY CustomerID
),
RankedCustomers AS (
    SELECT
        CustomerID,
        Total_Spending,
        ROW_NUMBER() OVER (
            ORDER BY Total_Spending DESC, CustomerID
        ) AS Customer_Rank
    FROM CustomerSpending
)
SELECT
    SUM(CASE
        WHEN Customer_Rank <= 10 THEN Total_Spending
        ELSE 0
    END) AS Top_10_Customer_Revenue,
    SUM(Total_Spending) AS Identified_Customer_Revenue,
    CAST(
        100.0 * SUM(CASE
            WHEN Customer_Rank <= 10 THEN Total_Spending
            ELSE 0
        END) / NULLIF(SUM(Total_Spending), 0)
        AS DECIMAL(10,2)
    ) AS Top_10_Revenue_Percentage
FROM RankedCustomers;




SELECT
    SUM(CASE
        WHEN InvoiceNo NOT LIKE 'C%'
         AND Quantity > 0
         AND UnitPrice > 0
        THEN Quantity * UnitPrice
        ELSE 0
    END) AS Gross_Sales,

    SUM(CASE
        WHEN Quantity < 0
         AND InvoiceNo NOT LIKE 'C%'
        THEN ABS(Quantity * UnitPrice)
        ELSE 0
    END) AS Potential_Return_Value,

    SUM(CASE
        WHEN InvoiceNo LIKE 'C%'
        THEN 1
        ELSE 0
    END) AS Cancellation_Lines,

    COUNT(DISTINCT CASE
        WHEN InvoiceNo NOT LIKE 'C%'
         AND Quantity > 0
         AND UnitPrice > 0
        THEN InvoiceNo
    END) AS Sales_Invoices,

    COUNT(DISTINCT CASE
        WHEN CustomerID IS NOT NULL
         AND InvoiceNo NOT LIKE 'C%'
         AND Quantity > 0
         AND UnitPrice > 0
        THEN CustomerID
    END) AS Identified_Customers,

    CAST(
        SUM(CASE
            WHEN InvoiceNo NOT LIKE 'C%'
             AND Quantity > 0
             AND UnitPrice > 0
            THEN Quantity * UnitPrice
            ELSE 0
        END)
        / NULLIF(
            COUNT(DISTINCT CASE
                WHEN InvoiceNo NOT LIKE 'C%'
                 AND Quantity > 0
                 AND UnitPrice > 0
                THEN InvoiceNo
            END) * 1.0,
            0
        )
        AS DECIMAL(12,2)
    ) AS Average_Sales_Invoice_Value

FROM dbo.online_retail; 