/*QUERY 8: No of order and value at Pending status in 2014 */

SELECT
      EXTRACT(YEAR FROM ModifiedDate) as yr,
      Status,
      COUNT( DISTINCT PurchaseOrderID) as order_cnt,
      SUM(TotalDue) as value
FROM  `adventureworks2019.Purchasing.PurchaseOrderHeader`
WHERE Status = 1 AND EXTRACT(YEAR FROM ModifiedDate) = 2014
GROUP BY yr,Status;