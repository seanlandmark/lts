USE [Invoice];
GO

/*
Dashboard metric: Lee Health bi-weekly totals

Purpose:
- Count billable non-Main Trip records
- Sum order total amount
- Sum total three-leg route distance

Notes:
- FORM_ID 1044 / Main Trip is excluded.
- Use ISO date literals for SQL Server safety.
- Replace the date range values from the dashboard layer when parameterizing.
*/

SELECT
    COUNT(*) AS Trip_Count,
    SUM(ORDER_TOTAL_AMOUNT) AS Biweekly_Order_Total,
    SUM(DISTANCE) AS Biweekly_Distance_Total
FROM [Invoice].[dbo].[PCT_DUMP]
WHERE FORM_ID <> 1044
  AND Date_of_Service BETWEEN '2026-06-16' AND '2026-06-30';
GO
