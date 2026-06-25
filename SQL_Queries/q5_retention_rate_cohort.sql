/* QUERY 5: Retention rate of Customer in 2014 with status of Successfully Shipped (Cohort Analysis)*/

With info as 
( SELECT
    EXTRACT(month from ModifiedDate) as mth_order,
    EXTRACT(year from ModifiedDate) as yr,
    CustomerID,
    count(distinct SalesOrderID) as sales_cnt
  FROM `adventureworks2019.Sales.SalesOrderHeader`
  where Status = 5 AND EXTRACT(year from ModifiedDate) = 2014
  GROUP BY 1,2,3    
)

, row_num as (
  select * ,row_number() over (partition by CustomerID order by mth_order asc) as row_nb
  from info
),

first_order as (
  select distinct mth_order as mth_join, yr, CustomerID
  from  row_num
  where row_nb = 1
),

all_join as (
  select 
  distinct a.mth_order,
   a.yr,
   a.CustomerID,
   b.mth_join,
   CONCAT('M',a.mth_order - b.mth_join) as mth_diff
  from info a
  LEFT JOIN first_order  b
  on a.CustomerID = b.CustomerID
  ORDER BY 3
)

SELECT 
 DISTINCT mth_join,mth_diff 
 ,count(distinct CustomerID) as custopmer_cnt
FROM all_join
GROUP BY 1,2
ORDER BY 1;