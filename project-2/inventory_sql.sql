CREATE DATABASE InventoryAnalytics;
use InventoryAnalytics;
alter table inventory_cleaned
modify column month varchar(20);

select count(*) as total_rows
from InventoryAnalytics.inventory_cleaned;

## verifying our table

select * from inventoryanalytics.inventory_cleaned
limit 10;

## Overall Inventory Performnce
 select sum(opening_stock) as total_opening_stock,
        sum(units_received) as total_units_received,
        sum(units_sold) as total_units_sold,
        sum(spoilage_units) as total_spoilage_units,
        sum(lost_sales_units) as total_lost_sales,
        sum(closing_stock) as total_closing_stock
 from inventoryanalytics.inventory_cleaned;       
 
 ## Category Sales Performance
 select category, sum(units_sold) as total_units_sold
 from inventoryanalytics.inventory_cleaned
 group by category
 order by total_units_sold desc;
 
 ##Stock Utilization Rate
 select (sum(units_sold)/sum(opening_stock))*100 as stock_utilization_rate
 from inventoryanalytics.inventory_cleaned;
 
 ## Monthly Units Sold
 select month, sum(units_sold) as total_units_sold
 from inventoryanalytics.inventory_cleaned
 group by month
 order by total_units_sold desc;
 
 ## Stockout Records by each category - Stockout Analysis
 select category, sum(stockout_flag) as stockout_records
 from inventoryanalytics.inventory_cleaned
 group by category
 order by stockout_records desc;
 
## Reorder Point Analysis
select product_id, avg(reorder_point) as Average_Reorder_Point
from inventoryanalytics.inventory_cleaned
group by product_id
order by Average_Reorder_point desc;
 
 ## Safety Stock Analysis
 select product_id, avg(safety_stock) as Average_Safety_Stock
 from inventoryanalytics.inventory_cleaned
 group by product_id
 order by Average_Safety_Stock desc;
 
 ## Product Spoilage Analysis
 select product_id, sum(spoilage_units) as Total_Spoilage_Units
 from inventoryanalytics.inventory_cleaned
 group by product_id
 order by Total_spoilage_Units desc;
 
 ## Store Sales Performance
 select store_id, sum(units_sold) as Total_Units_Sold
 from inventoryanalytics.inventory_cleaned
 group by store_id
 order by Total_Units_Sold desc;
 
 ## Identify products where the total units sold are greater than the average total units sold across all products
 select product_id, sum(units_sold) as Total_Units_Sold
 from inventoryanalytics.inventory_cleaned
 group by product_id
 having Total_Units_Sold>(select avg(product_Total) 
                             from (
                             select product_id, sum(units_sold) as product_Total
                             from inventoryanalytics.inventory_cleaned
                             group by product_id ) as product_sales)
order by Total_Units_Sold desc;

## Identify the stockout events and calculate the total lost sales units for each store
select store_id, sum(stockout_flag) as stockout_events,
                 sum(lost_sales_units) as total_lost_sales
from inventoryanalytics.inventory_cleaned
group by store_id
order by total_lost_sales desc;

## calculate the total_units_sold, total_spoilage_units, total_lost_sales_units by each category
 select category, sum(units_sold) as Total_Units_Sold,
                  sum(spoilage_units) as Total_Spoilage_Units,
                  sum(lost_sales_units) as Total_Lost_Sales
	from inventoryanalytics.inventory_cleaned
    group by category;
              
## Identify all the inventory records where closing_stock is below the safety_stock
 select store_id, product_id,category,closing_stock,safety_stock
 from inventoryanalytics.inventory_cleaned
 where closing_stock<safety_stock;
 
 ## Identify all the inventory records where closing_stock is below the reorder_point
 select store_id, product_id,category,closing_stock,reorder_point
 from inventoryanalytics.inventory_cleaned
 where closing_stock<reorder_point;
 
 ## High Demand,Low Stock Products
 select store_id, product_id,category,units_sold,closing_stock
 from inventoryanalytics.inventory_cleaned
 where units_sold>closing_stock;
 
 ## identify all inventory records where stockout occurred(stockout_flag=1) and display the related lost sales units
 select store_id,product_id,category,stockout_flag,lost_sales_units
 from inventoryanalytics.inventory_cleaned
 where stockout_flag =1;
 
 ## classify each inventory record into a stock status based on closing_stock
 
 select store_id,product_id,closing_stock,reorder_point,
 case
 when closing_stock =0 then "out of stock"
 when closing_stock<0 then "low stock"
 else "healthy stock"
 end as stock_status
 from inventoryanalytics.inventory_cleaned;
 
 ## category stockout rate
 select category,count(*) as total_records,
 sum(case
         when stockout_flag=1 then 1
         else 0
         end) as stockout_records,
         cast(sum(case
                    when stockout_flag=1 then 1
                    else 0
                    end)*100/count(*) as decimal(10,2)
			 ) as stockout_rate
          from inventoryanalytics.inventory_cleaned
          group by category
          order by stockout_rate desc;
          
 
 ## calculate the total units sold for each  product and assign a rank to each product based on total units sold
 select product_id, sum(units_sold) as total_units_sold,
 rank() over(order by sum(units_sold) desc) as sales_rank
 from inventoryanalytics.inventory_cleaned
 group by product_id
 order by sales_rank; 
 
 # Find the highest selling product within each product category based on total units sold
with product_sales as(
  select product_id,category,sum(units_sold) as total_units_sold
  from inventoryanalytics.inventory_cleaned
  group by product_id,category),
  ranked_product as(
  select product_id,category,total_units_sold,
  rank() over (partition by category order by total_units_sold) as rn
  from product_sales
  ) 
  select product_id, category,total_units_sold
  from ranked_product
  where rn=1
  order by category;
 
 ## which stores experienced the highest number of stockout events
 select store_id,sum(stockout_flag) as stockout_events
 from inventoryanalytics.inventory_cleaned
 group by store_id
 order by sum(stockout_flag) desc;
 
 ## store performance vs overall average
 select store_id, avg(closing_stock) as avg_closing_stock
 from inventoryanalytics.inventory_cleaned
 group by store_id
 having avg(closing_stock)>(
		select avg(closing_stock)
        from inventoryanalytics.inventory_cleaned)
  order by avg_closing_stock desc;     
  
  ## store ranking by stockout rate
  with store_stats as(
   select store_id,count(*) as total_records,
   sum(case
           when stockout_flag=1 then 1
           else 0
           end) as stockout_records
           from inventoryanalytics.inventory_cleaned
           group by store_id
           ),
        store_rates as (
           select store_id,total_records,stockout_records,
           cast(stockout_records*100/total_records as decimal(10,2)) as stockout_rate
           from store_stats)
          select store_id,total_records,stockout_records,stockout_rate,
           rank() over(order by stockout_rate) as stockout_rank
            from store_rates
            order by stockout_rank;
              
   ## cumulative units sold over time
   select week_start,sum(units_sold) as weekly_units_sold,
   sum(sum(units_sold)) over (order by week_start) as cumulative_units_sold
   from inventoryanalytics.inventory_cleaned
   group by week_start
   order by week_start;
   
   ## inventory turnover by category
   select category,avg((opening_stock+closing_stock)/2) as average_inventory,
   sum(units_sold) as total_units_sold,
  round( sum(units_sold)/nullif(avg((opening_stock+closing_stock)/2),0),2) as inventory_turnover
   from inventoryanalytics.inventory_cleaned
   group by category;
   
   ## Products with above average sales
   select product_id, sum(units_sold) as total_units_sold
   from inventoryanalytics.inventory_cleaned
   group by product_id
   having sum(units_sold)>(select avg(units_sold)
                            from inventoryanalytics.inventory_cleaned)
    order by total_units_sold desc;                  
    
    ## stores with no stockout events
    select store_id, count(*) as total_records
    from inventoryanalytics.inventory_cleaned
    group by store_id
    having sum(stockout_flag)=0;
    
    
## Identify the products with the highest total lost sales units
select product_id,sum(units_sold) as total_units_sold
from inventoryanalytics.inventory_cleaned
group by product_id
order by total_units_sold desc
limit 5;

## Find average inventory rate for each category
select category, avg((opening_stock+closing_stock)/2) as avg_inventory
from inventoryanalytics.inventory_cleaned
group by category
order by avg_inventory;
   
## Calculate Stock utilization rate for each store  
select store_id, (sum(units_sold)/sum(units_received)*100) as stock_utilization_rate
from inventoryanalytics.inventory_cleaned
group by store_id
order by stock_utilization_rate;