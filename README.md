# 💻 Bicycle_Manufacturer_Performance_Analysis | SQL, BigQuery  

<p align="center">
  <img src="documents/top_bicycle_brands_2024-1.jpg" width="80%">
</p>

**Author:** Le Anh Tuan

**Tools Used:** SQL

## 📑 Table of Contents

[📌 Background & Overview](#-background--overview)  
[📂 Dataset Description & Data Structure](#-dataset-description--data-structure)  
[🗂️ Project Structure](#️-project-structure)  
[🔎 Final Conclusion & Recommendations](#-final-conclusion--recommendations)  

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

## 📂 Dataset Description & Data Structure

**📌 Data Source**: The sample data is from **Google Analytics 4 (GA4)**, exported to **BigQuery**, including user activity data from the **Google Merchandise Store** e-commerce website.

**📌 Data Size**:

- **Dataset**: `ga4_obfuscated_sample_ecommerce`

**📌 How to Access the Data:**
1. Log in to your **Google Cloud Platform** account and create a new project.
2. Open the **BigQuery Console** and select your project.
3. Click on **"Add Data"** in the navigation panel, then choose **"Search a project"**.
4. In the search bar, enter the project ID: `bigquery-public-data.google_analytics_sample.ga_sessions` and press **Enter**.
5. Click on the `ga_sessions_` table to explore its structure and data.

## ⚒️ Main Process

Below is the execution of all 8 operational queries. They are presented here with their logic and a sample of their output results so you can explore the insights directly.

<details>
<summary><b>Query 1: lume L12M</b> (Cl</b> (Click to expand)</summary>

### 🔍 Question: Calc Quantity of items, Sales value & Order quantity by each Subcategory in L12M.

**Tracking the last 12 months of sales by subcategory helps the business spot which product lines are growing or declining in real time - so inventory and marketing budgets can be adjusted before it's too late.**

### 🚀 Queries

```sql
SELECT 
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    sum(totals.visits) as visits,
    sum(totals.pageviews) as pageviews,
    sum(totals.transactions) as transactions
 FROM `bigquery-public-data.google_analytics_sample.ga_sessions_2017*` 
WHERE _table_suffix between '0101' and '0331'
group by month
order by month;
```

### 💡 Queries result

![Image](https://github.com/user-attachments/assets/42eea66b-3f63-46af-9a9f-87d4033262a0)

</details>

<details>
<summary><b>Query 2: YoY Growth Rate by Category</b> (Click to expand)</summary>

### 🔍 Question: Calc % YoY growth rate by SubCategory & release top 3 cat with highest grow rate.

**Identifying the top 3 fastest-growing subcategories gives leadership a clear signal of where demand is heading - useful for production planning and deciding where to invest next.**

### 🚀 Queries

```sql
SELECT
    trafficSource.source as source,
    sum(totals.visits) as total_visits,
    sum(totals.Bounces) as total_no_of_bounces,
    (sum(totals.Bounces)/sum(totals.visits))* 100.00 as bounce_rate
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
GROUP BY source
ORDER BY total_visits DESC;
```

### 💡 Queries result

![Image](https://github.com/LeAnhTuan289/Ecommerce-Web-Performance-Purchase-Behavior-Analysis-SQL-BigQuery-/blob/d87e0decbd98c30c541c54f4a0c6a032c388b604/documents/q2.png)

</details>

<details>
<summary><b>Query 3: Top Territories by Year</b> (Click to expand)</summary>

### 🔍 Question: Ranking Top 3 TeritoryID with biggest Order quantity of every year. If there's TerritoryID with same quantity in a year, do not skip the rank number.

**Knowing which territories consistently drive the most orders helps the sales team prioritize regional resources and flag underperforming areas that may need support.**

### 🚀 Queries

```sql
with 
month_data as(
  SELECT
    "Month" as time_type,
    format_date("%Y%m", parse_date("%Y%m%d", date)) as month,
    trafficSource.source AS source,
    SUM(p.productRevenue)/1000000 AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
    unnest(hits) hits,
    unnest(product) p
  WHERE p.productRevenue is not null
  GROUP BY 1,2,3
  order by revenue DESC
),

week_data as(
  SELECT
    "Week" as time_type,
    format_date("%Y%W", parse_date("%Y%m%d", date)) as week,
    trafficSource.source AS source,
    SUM(p.productRevenue)/1000000 AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201706*`,
    unnest(hits) hits,
    unnest(product) p
  WHERE p.productRevenue is not null
  GROUP BY 1,2,3
  order by revenue DESC
)

select * from month_data
union all
select * from week_data
order by time_type
```

### 💡 Queries result

![Image](https://github.com/LeAnhTuan289/Ecommerce-Web-Performance-Purchase-Behavior-Analysis-SQL-BigQuery-/blob/44c3bbff1268c641f356453c987c16c18203735c/documents/q3.png)

</details>

<details>
  
<summary><b>Query 4: Seasonal Discount Efficiency</b> (Click to expand)</summary>

### 🔍 Question: Calc Total Discount Cost belongs to Seasonal Discount for each SubCategory.

**Calculating the total cost of seasonal discounts per subcategory lets the finance team evaluate whether the promotions are worth the margin loss - and which categories are eating the most discount budget.**


### 🚀 Queries

```sql
with 
purchaser_data as(
  select
      format_date("%Y%m",parse_date("%Y%m%d",date)) as month,
      (sum(totals.pageviews)/count(distinct fullvisitorid)) as avg_pageviews_purchase,
  from `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
    ,unnest(hits) hits
    ,unnest(product) product
  where _table_suffix between '0601' and '0731'
  and totals.transactions>=1
  and product.productRevenue is not null
  group by month
),

non_purchaser_data as(
  select
      format_date("%Y%m",parse_date("%Y%m%d",date)) as month,
      sum(totals.pageviews)/count(distinct fullvisitorid) as avg_pageviews_non_purchase,
  from `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`
      ,unnest(hits) hits
    ,unnest(product) product
  where _table_suffix between '0601' and '0731'
  and totals.transactions is null
  and product.productRevenue is null
  group by month
)

select
    pd.*,
    avg_pageviews_non_purchase
from purchaser_data pd
full join non_purchaser_data using(month)
order by pd.month;
```

### 💡 Queries result

![Image](https://github.com/LeAnhTuan289/Ecommerce-Web-Performance-Purchase-Behavior-Analysis-SQL-BigQuery-/blob/44c3bbff1268c641f356453c987c16c18203735c/documents/q4.png)

</details>

<details>
<summary><b>Query 5: Cohort Retention Rate</b> (Click to expand)</summary>

### 🔍 Question: Retention rate of Customer in 2014 with status of Successfully Shipped (Cohort Analysis).

**Cohort retention shows exactly when customers stop coming back after their first purchase - giving the CRM team a window to step in with re-engagement campaigns before churn becomes permanent.**

### 🚀 Queries

```sql
select
    format_date("%Y%m",parse_date("%Y%m%d",date)) as month,
    sum(totals.transactions)/count(distinct fullvisitorid) as Avg_total_transactions_per_user
from `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
    ,unnest (hits) hits,
    unnest(product) product
where  totals.transactions>=1
and product.productRevenue is not null
group by month;
```

### 💡 Queries result

![Image](https://github.com/LeAnhTuan289/Ecommerce-Web-Performance-Purchase-Behavior-Analysis-SQL-BigQuery-/blob/44c3bbff1268c641f356453c987c16c18203735c/documents/q5.png)

</details>

<details>
<summary><b>Query 6: Stock Trend MoM</b> (Click to expand)</summary>

### 🔍 Question: Trend of Stock level & MoM diff % by all product in 2011

**Month-over-month stock changes reveal whether inventory is building up or running low for each product - helping the warehouse team avoid both overstock and stockout situations.**

### 🚀 Queries

```sql
SELECT
     FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', date)) AS month,
    ROUND(((SUM(product.productRevenue) / 1000000) / sum(totals.visits)),2) AS avg_revenue_by_user_per_visit
FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
WHERE
    _table_suffix BETWEEN '0701' AND '0731'
    AND totals.transactions IS NOT NULL
    AND product.productRevenue IS NOT NULL
group by month;
```

### 💡 Queries result

![Image](https://github.com/LeAnhTuan289/Ecommerce-Web-Performance-Purchase-Behavior-Analysis-SQL-BigQuery-/blob/44c3bbff1268c641f356453c987c16c18203735c/documents/q6.png)

</details>

<details>
<summary><b>Query 7: Stock-to-Sales Ratio</b> (Click to expand)</summary>

### 🔍 Question: Calc Ratio of Stock / Sales in 2011 by product name, by month.

**A high stock-to-sales ratio means the company is holding more inventory than it's selling - tying up cash. This query flags which products need faster turnover or reduced production.**

### 🚀 Queries

```sql
with buyer_list as(
    SELECT
        distinct fullVisitorId  
    FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
    , UNNEST(hits) AS hits
    , UNNEST(hits.product) as product
    WHERE product.v2ProductName = "YouTube Men's Vintage Henley"
    AND totals.transactions>=1
    AND product.productRevenue is not null
)

SELECT
  product.v2ProductName AS other_purchased_products,
  SUM(product.productQuantity) AS quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_201707*`
, UNNEST(hits) AS hits
, UNNEST(hits.product) as product
JOIN buyer_list using(fullVisitorId)
WHERE product.v2ProductName != "YouTube Men's Vintage Henley"
 and product.productRevenue is not null
 AND totals.transactions>=1
GROUP BY other_purchased_products
ORDER BY quantity DESC;
```

### 💡 Queries result

![Image](https://github.com/LeAnhTuan289/Ecommerce-Web-Performance-Purchase-Behavior-Analysis-SQL-BigQuery-/blob/44c3bbff1268c641f356453c987c16c18203735c/documents/q7.png)

</details>

<details>
<summary><b>Query 8: Pending Orders Breakdown</b> (Click to expand)</summary>

### 🔍 Question: No of order and value at Pending status in 2014.

**Pending purchase orders represent committed but undelivered spend - tracking their total value helps the procurement team manage cash flow and follow up with suppliers before delays impact production.**


### 🚀 Queries

```sql
WITH product_events AS (
  SELECT
    FORMAT_DATE("%Y%m", PARSE_DATE("%Y%m%d", date)) AS month,
    product.v2ProductName AS product_name,
    hits.eCommerceAction.action_type AS action_type,
    product.productRevenue AS revenue
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_2017*`,
    UNNEST(hits) AS hits,
    UNNEST(hits.product) AS product
  WHERE
    _TABLE_SUFFIX BETWEEN '0101' AND '0331'
)

,aggregated AS (
  SELECT
    month,
    COUNTIF(action_type = '2') AS num_product_view, 
    COUNTIF(action_type = '3')  AS num_addtocart,
    COUNTIF(action_type = '6' and revenue IS NOT NULL ) AS num_purchase
  FROM product_events
  GROUP BY month
)
SELECT
  month,
  num_product_view,
  num_addtocart,
  num_purchase,
  ROUND( (num_addtocart / num_product_view) * 100.0, 2) AS add_to_cart_rate,
  ROUND((num_purchase   / num_product_view) * 100.0, 2) AS purchase_rate
FROM aggregated
ORDER BY month;
```

### 💡 Queries result

![Image](https://github.com/LeAnhTuan289/Ecommerce-Web-Performance-Purchase-Behavior-Analysis-SQL-BigQuery-/blob/44c3bbff1268c641f356453c987c16c18203735c/documents/q8.png)

</details>

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

## 🔎 Final Conclusion & Recommendations

### 📌 Insights

- **Traffic Trends**: The **total visits** in January, February, and March 2017 showed consistent traffic, with March having the highest number of visits (69,931).
- **Revenue by Source**: **Direct** traffic contributed significantly to revenue in June 2017, with notable contributions from **Google** and **Mail** sources, indicating strong performance from these channels.
- **Bounce Rate Insights**: Traffic from sources like **phandroid.com** has a high bounce rate of **77.78%**, which suggests that users might not be engaging well with the content on landing pages.
- **Purchaser Behavior**: Customers who bought the **"YouTube Men's Vintage Henley"** showed interest in related products like **Google Men's Vintage Badge Tee Black**, which presents an opportunity for cross-selling.

### 📌 Recommendations

1. **Optimize Landing Pages for High Bounce Traffic**: Improve pages for sources with high bounce rates (e.g., **phandroid.com**) by enhancing content relevance and reducing page load times.
2. **Focus on Direct & Paid Traffic**: Increase investment in **Google Ads** and improve brand awareness to leverage high-performing **direct traffic** for better conversions.
3. **Boost Conversion for Non-Purchasers**: Simplify the checkout process and offer targeted promotions to convert high-pageview, non-purchasing users.
4. **Maximize Cross-Selling**: Use product recommendations for items like the **"YouTube Men's Vintage Henley"** to drive cross-sales and increase average order value.
