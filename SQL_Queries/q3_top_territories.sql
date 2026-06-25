/* Query 3: Ranking Top 3 TeritoryID with biggest Order quantity of every year. 
If there's TerritoryID with same quantity in a year, do not skip the rank number */

with year_order as 
  (SELECT 
       EXTRACT(YEAR FROM sord.ModifiedDate) year,
       TerritoryID,
       sum(OrderQty) as order_cnt
   FROM `adventureworks2019.Sales.SalesOrderDetail` sord
   LEFT JOIN  `adventureworks2019.Sales.SalesOrderHeader` sorh
   USING(SalesOrderID)
   GROUP BY EXTRACT(YEAR FROM sord.ModifiedDate),TerritoryID)

,ranked_id as (
  SELECT 
   year,
   TerritoryID,
   order_cnt,
   DENSE_RANK() OVER(PARTITION BY year ORDER BY order_cnt DESC) as rk
  FROM year_order
  ORDER BY year DESC)

SELECT 
  year,
  TerritoryID,
  order_cnt,
  rk
FROM ranked_id 
WHERE rk<= 3
;
