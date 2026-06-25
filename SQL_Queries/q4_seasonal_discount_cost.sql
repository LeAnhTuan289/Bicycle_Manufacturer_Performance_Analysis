/* QUERY 4: Calc Total Discount Cost belongs to Seasonal Discount for each SubCategory*/

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