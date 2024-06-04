

--drop table df_orders;

--CREATE TABLE [dbo].[df_orders](
--	[order_id] [int] Primary Key,
--	[order_date] [datetime] NULL,
--	[ship_mode] [varchar](20) NULL,
--	[segment] [varchar](20) NULL,
--	[country] [varchar](20) NULL,
--	[city] [varchar](20) NULL,
--	[state] [varchar](20) NULL,
--	[postal_code] [int] NULL,
--	[region] [varchar](20) NULL,
--	[category] [varchar](20) NULL,
--	[sub_category] [varchar](20) NULL,
--	[product_id] [varchar](20) NULL,
--	[quantity] [int] NULL,
--	[discount] [decimal](7,2) NULL,
--	[sale_price] [decimal](7,2) NULL,
--	[profit] [decimal](7,2) NULL
--)
--GO


---------------------------------------------------

select * from df_orders;

--find top 10 highest reveue generating products 

SELECT
	TOP 10 product_id,
	SUM (sale_price * quantity)  AS  sales
FROM df_orders
GROUP BY product_id  
ORDER BY  sales desc;

--find top 5 highest selling products in each region

WITH CTE  AS  (
	SELECT
		region,
		product_id,
		SUM (sale_price * quantity)  AS  sales
	FROM df_orders
	GROUP BY region, product_id
),
CTE2  AS  ( 
	SELECT
		*,
		row_number()  OVER (partition by region  ORDER BY  sales desc)  AS  rnk
	FROM CTE
) 
SELECT *
FROM CTE2
WHERE rnk <=5;


--find month over month growth comparison for 2022 and 2023 sales eg : jan 2022 vs jan 2023

WITH cte  AS  ( 
	SELECT
		year(order_date)  AS  order_year,
		month(order_date)  AS  order_month,
		SUM (sale_price * quantity)  AS  sales
	FROM
		df_orders
	GROUP BY
		year(order_date),
		month(order_date) 
) 
SELECT
	order_month ,
	SUM (CASE
			WHEN order_year=2022  THEN  sales
			ELSE 0  END )  AS  sales_2022 ,
	SUM (CASE
			WHEN order_year=2023  THEN  sales
			ELSE 0  END )  AS  sales_2023
FROM cte
GROUP BY order_month  
ORDER BY  order_month;





--for each category which month had highest sales 

WITH cte  AS  ( 
	SELECT
		category,
		format(order_date, 'yyyyMM')  AS  order_year_month ,
		SUM (sale_price * quantity)  AS  sales
	FROM
		df_orders
	GROUP BY
		category,
		format(order_date, 'yyyyMM') 
) 
SELECT *
FROM
( SELECT
	*,
	row_number()  OVER (partition by category  ORDER BY  sales desc)  AS  rn
	FROM
	cte ) a
WHERE
rn=1;



--which sub category had highest growth by profit in 2023 compare to 2022

WITH cte  AS  (
	SELECT
		sub_category,
		year(order_date)  AS  order_year,
		SUM (profit)  AS  profits
	FROM
		df_orders
	GROUP BY
		sub_category,
		year(order_date) 
) ,
cte2  AS  ( 
	SELECT
		sub_category ,
		SUM (CASE
				WHEN order_year=2022  THEN  profits
				ELSE 0  END )  AS  profits_2022 ,
		SUM (CASE
				WHEN order_year=2023  THEN  profits
				ELSE 0  END )  AS  profits_2023
	FROM
		cte
	GROUP BY
		sub_category 
)
SELECT top 1 * ,
	(profits_2023 - profits_2022)*100/profits_2022 AS Profit_growth
FROM
	cte2  
ORDER BY  
	Profit_growth desc;