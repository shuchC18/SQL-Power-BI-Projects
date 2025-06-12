-- Get the first 10 rows
SELECT* 
FROM coffeeshop 
LIMIT 10;
---------------------------------------------------------------------------
-- Count the total number of orders--
SELECT COUNT(*) AS total_orders FROM coffeeshop;
---------------------------------------------------------------------------
-- Count the total number of customers--
SELECT COUNT(DISTINCT cust_name) AS total_number_of_customers FROM coffeeshop;
---------------------------------------------------------------------------
-- Count the total reveue generated from sales--
SELECT SUM(o.quantity*i.item_price) AS total_sales
FROM orders o
JOIN items i on o.item_id = i.item_id;
---------------------------------------------------------------------------
-- Total Items: Summarize the variety of items sold--
SELECT
COUNT(DISTINCT item_cat) AS variety_of_items_sold
FROM items;
---------------------------------------------------------------------------
-- Total number of items sold--
SELECT
SUM(quantity) AS Total_number_of_items_sold
FROM orders;
---------------------------------------------------------------------------
-- Average Order Value: Determined the average revenue per order--
-- Average Order Value (AOV) is a key business metric that tells you: How much revenue you earn on average from each customer order--
-- AOV = Total Revenue / Total Number of Orders--
SELECT
SUM(o.quantity*i.item_price) / COUNT(DISTINCT o.order_id) AS Average_Order_Value
FROM orders o
JOIN items i on o.item_id = i.item_id;
---------------------------------------------------------------------------
-- Sales by Category: Analyzed revenue generation by item category--
SELECT
SUM(o.quantity*i.item_price) AS total_revenue, i.item_cat AS category
FROM orders o
JOIN items i on o.item_id = i.item_id
GROUP BY item_cat
ORDER BY total_revenue DESC;
---------------------------------------------------------------------------
-- Top Selling Items: Identified the most popular items--
SELECT
SUM(o.quantity) AS total_quantity_sold, i.item_name AS name_of_item
FROM orders o 
JOIN items i on o.item_id = i.item_id
GROUP BY name_of_item
ORDER BY total_quantity_sold DESC; 
---------------------------------------------------------------------------
-- Orders In or Out: Differentiated between dine-in and takeout orders --
SELECT 
 CASE
 WHEN TRIM(in_or_out) = '' OR in_or_out IS NULL THEN 'Not Known'
 ELSE in_or_out
 END AS in_or_out_consumption,
  row_id
FROM orders;

###############
SELECT
SUM(quantity) AS total_quantity, in_or_out_consumption AS consumption_loc
FROM (SELECT 
 CASE
 WHEN TRIM(in_or_out) = '' OR in_or_out IS NULL THEN 'Not Known'
 ELSE in_or_out
 END AS in_or_out_consumption,
  quantity
FROM orders) AS cleaned_orders
GROUP BY consumption_loc
ORDER BY total_quantity;
---------------------------------------------------------------------------
-- Total Quantity by Ingredient: Calculate the total usage of each ingredient--
SELECT
SUM(r.quantity * 
    CASE 
      WHEN t.ing_meas = 'grams' THEN t.ing_weight
      WHEN t.ing_meas = 'ml' THEN t.ing_weight * 1         -- ml ≈ g
      WHEN t.ing_meas = 'units' THEN t.ing_weight * 50      -- assume 1 unit = 50g
      ELSE 0
    END) AS Total_ingredient_grams, t.ing_name AS Name_of_ing
FROM recipe r 
JOIN ingredients t on r.ing_id = t.ing_id
GROUP BY Name_of_ing
ORDER BY Total_ingredient_grams DESC;
---------------------------------------------------------------------------
-- Total Cost of Ingredients: Estimated the overall cost of ingredients used--
SELECT
t.ing_name AS ingredient_name,
SUM(r.quantity * 
    CASE 
      WHEN t.ing_meas = 'grams' THEN t.ing_weight
      WHEN t.ing_meas = 'ml' THEN t.ing_weight * 1         -- ml ≈ g
      WHEN t.ing_meas = 'units' THEN t.ing_weight * 50      -- assume 1 unit = 50g
      ELSE 0
    END) AS Total_ingredient_grams, SUM(r.quantity * 
    CASE 
      WHEN t.ing_meas = 'grams' THEN t.ing_weight * t.ing_price
      WHEN t.ing_meas = 'ml' THEN t.ing_weight * 1 * t.ing_price
      WHEN t.ing_meas = 'units' THEN t.ing_weight * 50 * t.ing_price
      ELSE 0
    END) AS total_price
    FROM recipe r 
JOIN ingredients t on r.ing_id = t.ing_id
GROUP BY t.ing_name
ORDER BY total_price DESC;
---------------------------------------------------------------------------
-- Calculate Cost of Coffee: Determined the cost to produce each coffee item--
SELECT
 i.item_name, 
 i.item_size, 
 i.sku,
 ROUND(SUM(((r.quantity)/(ing.ing_weight))*ing.ing_price), 2) AS Production_Cost
FROM items i
JOIN recipe r on i.sku = r.recipe_id
JOIN ingredients ing on r.ing_id = ing.ing_id
GROUP BY i.item_name, i.item_size, i.sku
ORDER BY Production_Cost DESC;
---------------------------------------------------------------------------
-- Percentage Stock Remaining by Ingredients: Assessed stock levels as a percentage of total capacity--
SELECT
ing.ing_name,
stock.quantity,
ROUND(((stock.quantity) / (ing.ing_weight))*100, 2) as Percent_Stock_Remaining
FROM inventory stock
JOIN ingredients ing ON stock.ing_id = ing.ing_id
ORDER BY Percent_Stock_Remaining DESC;
-- Note: Percent_Stock_Remaining may exceed 100% for ingredients measured in 'units'
---------------------------------------------------------------------------
-- List of Ingredients to Re-order: Identified ingredients needing replenishment based on inventory levels--
-- Let's keep a threshold of 25% for ingredients that are to be reordered.
SELECT
ing.ing_name,
stock.quantity,
ing.ing_weight,
ing.ing_meas,
ROUND(((stock.quantity)/(ing.ing_weight))*100, 2) as Percent_Stock_Remaining
FROM inventory stock
JOIN ingredients ing ON stock.ing_id = ing.ing_id
WHERE (stock.quantity / ing.ing_weight) * 100 < 25
ORDER BY Percent_Stock_Remaining;
---------------------------------------------------------------------------
-- Profitability: calculate cost to produce each item (Production_Cost) and total sales.
SELECT 
  i.item_name,
  i.item_size,
  i.item_price,
  ROUND(SUM(((r.quantity)/(ing.ing_weight))*ing.ing_price), 3) AS production_cost,
  ROUND(i.item_price - SUM(((r.quantity)/(ing.ing_weight))*ing.ing_price), 2) AS profit_per_item
FROM items i
JOIN recipe r ON i.sku = r.recipe_id
JOIN ingredients ing ON r.ing_id = ing.ing_id
GROUP BY i.item_name, i.item_size, i.sku, i.item_price
ORDER BY profit_per_item DESC;
---------------------------------------------------------------------------
