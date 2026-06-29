# 💻 Bicycle_Manufacturer_Performance_Analysis | SQL, BigQuery  

<p align="center">
  <img src="documents/top_bicycle_brands_2024-1.jpg" width="80%">
</p>

**Author:** Le Anh Tuan

**Tools Used:** SQL

---

## 📑 Table of Contents

[📌 Background & Overview](#-background--overview)  
[📂 Dataset Description & Data Structure](#-dataset-description--data-structure)  
[🗂️ Project Structure](#️-project-structure)  
[🔎 Final Conclusion & Recommendations](#-final-conclusion--recommendations)  

---

## Background & Overview

### 📖 What is this project about? What Business Question will it solve?  

**Objective:**

- This project uses SQL (Google BigQuery) to analyze sales, production, and purchasing data from the **AdventureWorks dataset**
- It answers 8 specific business questions covering **Sales Performance, Customer Retention, and Inventory Optimization**
- The goal is to turn raw transactional and operational data into clear, actionable insights for the business

**Main business question:**

This project uses SQL to analyze sales, inventory, and purchasing data from AdventureWorks to:
- Identify which product categories, territories, and time periods drive the most sales
- Evaluate how discounts, customer retention, and stock levels affect overall business performance

## 👤 Who is this project for?  
- ✔️ **Data analysts & business analysts** who want a reference for writing analytical SQL (CTEs, window functions, cohort analysis)
- ✔️ **Decision-makers & stakeholders** who need quick insights into sales trends, inventory health, and supplier performance  

---

## 📂 Dataset Description & Data Structure

This project is an end-to-end data analysis performed on the **AdventureWorks database**, a comprehensive dataset simulating a large multinational manufacturing company. The business operates across multiple international regions, managing thousands of products, salespeople, and complex supply chain records.

### Data Dictionary

To execute the 8 operational queries in this project, I utilized **8 tables** across the `Sales`, `Production`, and `Purchasing` schemas. Below is a targeted data dictionary of the exact fields used in my analysis. 

> 🔗 **Full Documentation:** For the complete, un-abridged Data Dictionary of the entire AdventureWorks dataset, please refer to the [Official Data Dictionary (PDF)](https://drive.google.com/file/d/1bwwsS3cRJYOg1cvNppc1K_8dQLELN16T/view).

| Schema | Table Name | Columns Used in Queries | Business Purpose in Analysis |
| :--- | :--- | :--- | :--- |
| **Sales** | `SalesOrderHeader` | `SalesOrderID`, `OrderDate`, `CustomerID`, `TerritoryID`, `Status`, `ModifiedDate` | Base table for tracking cohort timelines, territory performance, and successful conversions. |
| **Sales** | `SalesOrderDetail` | `SalesOrderID`, `ProductID`, `OrderQty`, `LineTotal`, `UnitPrice`, `SpecialOfferID` | Fact table for aggregating total demand, volume, and revenue. |
| **Sales** | `SpecialOffer` | `SpecialOfferID`, `DiscountPct`, `Type` | Sourced the "Seasonal Discount" type and percentages for cost-efficiency tracking. |
| **Production** | `Product` | `ProductID`, `Name`, `ProductSubcategoryID` | Dimension table linking SKU IDs to human-readable names and category clusters. |
| **Production** | `ProductSubcategory` | `ProductSubcategoryID`, `Name` | Used to group specific bicycle models into high-level subcategories for YoY growth tracking. |
| **Production** | `WorkOrder` | `ProductID`, `StockedQty`, `ModifiedDate` | Core table specifying historical stocked quantities to measure month-over-month supply trends. |
| **Purchasing** | `PurchaseOrderHeader` | `PurchaseOrderID`, `Status`, `TotalDue`, `ModifiedDate` | Evaluated supplier backend performance by isolating `Status = 1` (Pending) orders. |
| **Purchasing** | `PurchaseOrderDetail` | `PurchaseOrderID` | Joined context for purchase order line items. |

---

## ⚒️ Main Process

Below is the execution of all 8 operational queries. They are presented here with their logic and a sample of their output results so you can explore the insights directly.

<details>
<summary><b>Query 1: lume L12M</b> (Cl</b> (Click to expand)</summary>

### 🔍 Question: Calc Quantity of items, Sales value & Order quantity by each Subcategory in L12M.

**Tracking the last 12 months of sales by subcategory helps the business spot which product lines are growing or declining in real time - so inventory and marketing budgets can be adjusted before it's too late.**

### 🚀 Queries

```sql
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
```

### 💡 Queries result

![Image](https://github.com/LeAnhTuan289/Bicycle_Manufacturer_Performance_Analysis/blob/e15924a697eb118c82938684efd5473bd7366e8f/documents/q1.png)

</details>

<details>
<summary><b>Query 2: YoY Growth Rate by Category</b> (Click to expand)</summary>

### 🔍 Question: Calc % YoY growth rate by SubCategory & release top 3 cat with highest grow rate.

**Identifying the top 3 fastest-growing subcategories gives leadership a clear signal of where demand is heading - useful for production planning and deciding where to invest next.**

### 🚀 Queries

```sql
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
order by qty_diff DESC ;
```

### 💡 Queries result

![Image](https://github.com/LeAnhTuan289/Bicycle_Manufacturer_Performance_Analysis/blob/e15924a697eb118c82938684efd5473bd7366e8f/documents/q2.png)

</details>

<details>
<summary><b>Query 3: Top Territories by Year</b> (Click to expand)</summary>

### 🔍 Question: Ranking Top 3 TeritoryID with biggest Order quantity of every year. 

**Knowing which territories consistently drive the most orders helps the sales team prioritize regional resources and flag underperforming areas that may need support.**

### 🚀 Queries

```sql
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
```

### 💡 Queries result

![Image](https://github.com/LeAnhTuan289/Bicycle_Manufacturer_Performance_Analysis/blob/e15924a697eb118c82938684efd5473bd7366e8f/documents/q3.png)

</details>

<details>
  
<summary><b>Query 4: Seasonal Discount Efficiency</b> (Click to expand)</summary>

### 🔍 Question: Calc Total Discount Cost belongs to Seasonal Discount for each SubCategory.

**Calculating the total cost of seasonal discounts per subcategory lets the finance team evaluate whether the promotions are worth the margin loss - and which categories are eating the most discount budget.**


### 🚀 Queries

```sql
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
```

### 💡 Queries result

![Image](https://github.com/LeAnhTuan289/Bicycle_Manufacturer_Performance_Analysis/blob/e15924a697eb118c82938684efd5473bd7366e8f/documents/q4.png)

</details>

<details>
<summary><b>Query 5: Cohort Retention Rate</b> (Click to expand)</summary>

### 🔍 Question: Retention rate of Customer in 2014 with status of Successfully Shipped (Cohort Analysis).

**Cohort retention shows exactly when customers stop coming back after their first purchase - giving the CRM team a window to step in with re-engagement campaigns before churn becomes permanent.**

### 🚀 Queries

```sql
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
```

### 💡 Queries result

![Image](https://github.com/LeAnhTuan289/Bicycle_Manufacturer_Performance_Analysis/blob/e15924a697eb118c82938684efd5473bd7366e8f/documents/q5.png)

</details>

<details>
<summary><b>Query 6: Stock Trend MoM</b> (Click to expand)</summary>

### 🔍 Question: Trend of Stock level & MoM diff % by all product in 2011

**Month-over-month stock changes reveal whether inventory is building up or running low for each product - helping the warehouse team avoid both overstock and stockout situations.**

### 🚀 Queries

```sql
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
```

### 💡 Queries result

![Image](https://github.com/LeAnhTuan289/Bicycle_Manufacturer_Performance_Analysis/blob/e15924a697eb118c82938684efd5473bd7366e8f/documents/q6.png)

</details>

<details>
<summary><b>Query 7: Stock-to-Sales Ratio</b> (Click to expand)</summary>

### 🔍 Question: Calc Ratio of Stock / Sales in 2011 by product name, by month.

**A high stock-to-sales ratio means the company is holding more inventory than it's selling - tying up cash. This query flags which products need faster turnover or reduced production.**

### 🚀 Queries

```sql
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
```

### 💡 Queries result

![Image](https://github.com/LeAnhTuan289/Bicycle_Manufacturer_Performance_Analysis/blob/e15924a697eb118c82938684efd5473bd7366e8f/documents/q7.png)

</details>

<details>
<summary><b>Query 8: Pending Orders Breakdown</b> (Click to expand)</summary>

### 🔍 Question: No of order and value at Pending status in 2014.

**Pending purchase orders represent committed but undelivered spend - tracking their total value helps the procurement team manage cash flow and follow up with suppliers before delays impact production.**


### 🚀 Queries

```sql
SELECT
      EXTRACT(YEAR FROM ModifiedDate) as yr,
      Status,
      COUNT( DISTINCT PurchaseOrderID) as order_cnt,
      SUM(TotalDue) as value
FROM  `adventureworks2019.Purchasing.PurchaseOrderHeader`
WHERE Status = 1 AND EXTRACT(YEAR FROM ModifiedDate) = 2014
GROUP BY yr,Status;
```

### 💡 Queries result

![Image](https://github.com/LeAnhTuan289/Bicycle_Manufacturer_Performance_Analysis/blob/e15924a697eb118c82938684efd5473bd7366e8f/documents/q8.png)

</details>

---

## 🗂️ Project Structure

```text
Bicycle_Manufacturer_Performance_Analysis/
├── documents/                         # Contains query result output images
│   ├── q1.png
│   ├── ...
│   └── q8.png
├── query/                             
│   ├── q1_sales_performance_l12m.sql
│   ├── q2_yoy_growth_top_categories.sql
│   ├── q3_top_territories.sql
│   ├── q4_seasonal_discount_cost.sql
│   ├── q5_retention_rate_cohort.sql
│   ├── q6_stock_trend_mom.sql
│   ├── q7_stock_to_sales_ratio.sql
│   └── q8_pending_orders_2014.sql
└── README.md                          
```

---

## 🔎 Final Conclusion & Recommendations

### 📌 Key Business Insights

#### 🚵 Mountain Frames Became the Company's Primary Growth Driver

Mountain Frames recorded the highest Year-over-Year revenue growth (+521%), significantly outperforming every other product category. This indicates a strong shift in customer demand and suggests that Mountain Frames will likely remain the company's primary revenue growth engine if sufficient inventory and marketing investment are maintained.

---

#### 💰 Promotional Spending Is Growing Faster Than Sales Efficiency

Seasonal discount costs increased substantially across several product categories, particularly Helmets. The business appears to rely increasingly on promotional campaigns to stimulate demand, which may gradually erode gross profit margins if promotional effectiveness is not continuously evaluated.

---

#### 👥 Customer Acquisition Is Strong, but Retention Remains a Key Weakness

Cohort analysis reveals that only a small proportion of customers return after their initial purchase. While the company successfully attracts new customers, limited repeat purchasing restricts Customer Lifetime Value (CLV) and increases dependence on continuous customer acquisition.

---

#### 📦 Inventory Allocation Is Not Fully Aligned with Market Demand

Several products maintain considerably higher inventory levels relative to their sales performance, resulting in inefficient capital allocation and increased inventory holding costs. Inventory planning should better reflect actual sales demand to improve operational efficiency.

### 📌 Business Recommendations

#### 🚀 Prioritize Investment in High-Growth Categories

Increase inventory capacity and marketing investment for Mountain Frames while introducing premium product bundles to maximize revenue growth and Average Order Value (AOV).

---

#### 🎯 Optimize Promotional Effectiveness

Shift from broad discount campaigns toward personalized promotions and loyalty incentives. Continuously monitor Promotion ROI and Gross Margin to balance revenue growth with profitability.

---

#### ❤️ Strengthen Customer Retention Strategy

Develop post-purchase engagement programs, including maintenance reminders, loyalty rewards, and personalized accessory recommendations to encourage repeat purchases and increase Customer Lifetime Value (CLV).

---

#### 📊 Improve Inventory Planning

Adopt demand-driven inventory management by monitoring Inventory Turnover and Stock-to-Sales Ratios. Reduce production of slow-moving products while ensuring sufficient inventory for high-demand categories.

