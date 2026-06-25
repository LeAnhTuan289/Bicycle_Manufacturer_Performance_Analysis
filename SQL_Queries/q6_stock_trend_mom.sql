/*QUERY 6: Trend of Stock level & MoM diff % by all product in 2011. 
If %gr rate is null then 0. Round to 1 decimal*/

WITH stock_cr AS 
( SELECT 
       prd.Name as name,
       EXTRACT(month FROM wod.ModifiedDate) as mth,
       EXTRACT(YEAR FROM wod.ModifiedDate) as yr,
       SUM(StockedQty) as stock_qty
  FROM `adventureworks2019.Production.Product` prd
  LEFT JOIN `adventureworks2019.Production.WorkOrder` wod
  USING(ProductID)
  WHERE EXTRACT(YEAR FROM wod.ModifiedDate)= 2011
  GROUP BY name,mth,yr
  ORDER BY name,mth DESC)

,cr_prev as
( SELECT 
        name,
        mth,
        yr,
        stock_qty,
        LEAD(stock_qty) OVER(PARTITION BY name ORDER BY mth DESC) as stock_prv     
  FROM stock_cr
  ORDER BY name
)

SELECT 
    name,
    mth,
    yr,
    stock_qty,
    stock_prv,
    COALESCE(ROUND((stock_qty - stock_prv) / stock_prv * 100.0 , 1) ,0) as diff
FROM cr_prev;