-- qry 1
select format_datetime('%b %Y', a.ModifiedDate) month
      ,c.Name
      ,sum(a.OrderQty) qty_item
      ,sum(a.LineTotal) total_sales
      ,count(distinct a.SalesOrderID) order_cnt
FROM `adventureworks2019.Sales.SalesOrderDetail` a 
left join `adventureworks2019.Production.Product` b
  on a.ProductID = b.ProductID
left join `adventureworks2019.Production.ProductSubcategory` c
  on b.ProductSubcategoryID = cast(c.ProductSubcategoryID as string)

where date(a.ModifiedDate) >=  (select date_sub(date(max(a.ModifiedDate)), INTERVAL 12 month)
                                from `adventureworks2019.Sales.SalesOrderDetail` ) -- 2013-06-30
group by 1,2
order by 2,1;

-- qry 2
with 
sale_info as (
  SELECT 
      FORMAT_TIMESTAMP("%Y", a.ModifiedDate) as yr
      , c.Name
      , sum(a.OrderQty) as qty_item

  FROM `adventureworks2019.Sales.SalesOrderDetail` a 
  LEFT JOIN `adventureworks2019.Production.Product` b on a.ProductID = b.ProductID
  LEFT JOIN `adventureworks2019.Production.ProductSubcategory` c on cast(b.ProductSubcategoryID as int) = c.ProductSubcategoryID
  GROUP BY 1,2
  ORDER BY 2 asc , 1 desc
),

sale_diff as (
  select 
  yr
  ,Name
  ,qty_item
  ,lead (qty_item) over (partition by Name order by yr desc) as prv_qty
  ,round(qty_item / (lead (qty_item) over (partition by Name order by yr desc)) -1,2) as qty_diff
  from sale_info
  order by 5 desc 
),

rk_qty_diff as (
  select 
    yr
    ,Name
    ,qty_item
    ,prv_qty
    ,qty_diff
    ,dense_rank() over( order by qty_diff desc) dk
  from sale_diff
)

select distinct Name
      , qty_item
      , prv_qty
      , qty_diff
from rk_qty_diff 
where dk <=3
order by dk ;

-- qry 3
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


--qry 4
with per_cgry as 
( SELECT 
   EXTRACT(YEAR FROM sord.ModifiedDate) as year,
   prds.Name AS name,
   (DiscountPct * UnitPrice * OrderQty) as Discount_cost
  FROM `adventureworks2019.Sales.SalesOrderDetail` sord
  LEFT JOIN `adventureworks2019.Production.Product` prod
    ON sord.ProductID = prod.ProductID
  LEFT JOIN `adventureworks2019.Production.ProductSubcategory` prds
    ON CAST(prod.ProductSubcategoryID AS INT) = prds.ProductSubcategoryID
  LEFT JOIN `adventureworks2019.Sales.SpecialOffer` sof
    USING(SpecialOfferID)
  WHERE type like '%Seasonal Discount%')

SELECT
    year,
    name,
    sum(Discount_cost) as total_cost
FROM per_cgry
GROUP BY year,name
ORDER BY year;


--qry 5
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

-- correct

--qry 6
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


-- qry 7
with 
sale_info as (
  select 
      extract(month from a.ModifiedDate) as mth 
     , extract(year from a.ModifiedDate) as yr 
     , a.ProductId
     , b.Name
     , sum(a.OrderQty) as sales
  from `adventureworks2019.Sales.SalesOrderDetail` a 
  left join `adventureworks2019.Production.Product` b 
    on a.ProductID = b.ProductID
  where FORMAT_TIMESTAMP("%Y", a.ModifiedDate) = '2011'
  group by 1,2,3,4
), 

stock_info as (
  select
      extract(month from ModifiedDate) as mth 
      , extract(year from ModifiedDate) as yr 
      , ProductId
      , sum(StockedQty) as stock_cnt
  from 'adventureworks2019.Production.WorkOrder'
  where FORMAT_TIMESTAMP("%Y", ModifiedDate) = '2011'
  group by 1,2,3
)

select
      a.mth
    , a.yr
    , a.ProductId
    , a.Name
    , a.sales
    , b.stock_cnt as stock  --(*)
    , round(coalesce(b.stock_cnt,0) / sales,2) as ratio
from sale_info a 
full join stock_info b 
  on a.ProductId = b.ProductId
and a.mth = b.mth 
and a.yr = b.yr
order by 1 desc, 7 desc;


--qry 8
SELECT
      EXTRACT(YEAR FROM ModifiedDate) as yr,
      Status,
      COUNT( DISTINCT PurchaseOrderID) as order_cnt,
      SUM(TotalDue) as value
FROM  `adventureworks2019.Purchasing.PurchaseOrderHeader`
WHERE Status = 1 AND EXTRACT(YEAR FROM ModifiedDate) = 2014
GROUP BY yr,Status;

