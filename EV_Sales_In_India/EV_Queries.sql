
-- total sales from 2014 to 2024 
SELECT 
    state, SUM(EV_Sales_Quantity) AS total_sales
FROM
    sales
GROUP BY state
ORDER BY total_sales DESC;

-- number of sales in each state 
SELECT 
    state, COUNT(*) AS sales_num
FROM
    sales
GROUP BY state
ORDER BY sales_num DESC;

-- sale rate 
WITH num_sales AS (SELECT 
						year, 
                        state, 
                        COUNT(*) as sales_num 
					FROM sales 
					GROUP BY year, state
					ORDER BY sales_num DESC), 
	sales_total AS (SELECT 
							state, 
                            SUM(EV_Sales_Quantity) as total_sales
					FROM sales 
					GROUP BY state
					ORDER BY total_sales DESC)
    SELECT 
		ns.state, 
        ns. year,
        ROUND(ts.total_sales/ns.sales_num, 2) AS sale_rate
    FROM num_sales ns
    JOIN sales_total ts 
    ON ns.state = ts.state
    ORDER BY sale_rate DESC;
    
-- yearly sales 
SELECT 
    year, SUM(EV_Sales_Quantity) AS yearly_sales
FROM
    sales
GROUP BY year
ORDER BY year DESC; 

-- percent of total sales 
SELECT 
	state, 
    SUM(EV_sales_quantity) as total_sales,
	ROUND(SUM(EV_sales_quantity) * 100.0 / SUM(SUM(EV_sales_quantity)) OVER(), 2) AS pct_of_total
FROM sales
GROUP BY state
ORDER BY total_sales DESC;

-- OR 

-- pct_of_total 
WITH state_sales AS (
		SELECT 
			DISTINCT state, 
			SUM(EV_Sales_Quantity) OVER(PARTITION BY state) as total_sales
		FROM sales
) 
SELECT 
	state, 
    total_sales, 
	ROUND(total_sales * 100 /SUM(total_sales) OVER(), 2) AS pct_of_total 
FROM state_sales
ORDER BY total_sales DESC; 

-- YoY sales analysis [2014-2024]
SELECT 
	year, 
    SUM(EV_sales_quantity) as present_year_sales, 
	LAG(SUM(EV_sales_quantity)) OVER(ORDER BY Year) as previous_year_sales, 
	ROUND((SUM(EV_sales_quantity)- LAG(SUM(EV_sales_quantity)) OVER(ORDER BY Year)) * 100 /LAG(SUM(EV_sales_quantity)) OVER(ORDER BY Year), 2) 
		as pct_change
FROM sales
GROUP BY year; 

-- MoM sales analysis for 2023 
SELECT 
	month_name, 
	SUM(EV_sales_quantity) AS present_month_sales, 
	LAG(SUM(ev_sales_quantity)) OVER(ORDER BY MONTH(date)) as previous_month_sales, 
	ROUND((SUM(EV_sales_quantity) - LAG(SUM(ev_sales_quantity)) OVER(ORDER BY MONTH(date))) *100/LAG(SUM(ev_sales_quantity)) OVER(ORDER BY MONTH(date)), 2) 
	as pct_change
FROM sales 
WHERE year = 2023
GROUP BY month_name, month(date); 

-- vehicle category analysis 
SELECT 
	vehicle_category, 
    SUM(EV_sales_quantity) as total_sales,
	ROUND(SUM(EV_sales_quantity) * 100.0 / SUM(SUM(EV_sales_quantity)) OVER(), 2) 
		AS pct_sales
FROM sales 
GROUP BY vehicle_category 
ORDER BY total_sales DESC;

-- total states 
SELECT 
    COUNT(*)
FROM
    (SELECT DISTINCT
        state, COUNT(*)
    FROM
        sales
    WHERE
        EV_Sales_Quantity > 0
    GROUP BY state) AS t;


/** GOI Launced FAME-2 Scheme in 2019 to promote the adoption of electric vehicles in India.
Analysis of the launch of the scheme on the sales based on the vehicle category **/ 
SELECT 
    vehicle_category,
    pre_FAME,
    post_FAME,
    ROUND((post_FAME - pre_FAME) * 100.0 / pre_FAME,
            2) AS pct_increase
FROM
    (SELECT 
        vehicle_category,
            SUM(CASE
                WHEN year < 2019 THEN EV_sales_quantity
            END) AS pre_FAME,
            SUM(CASE
                WHEN year >= 2019 THEN EV_sales_quantity
            END) AS post_FAME
    FROM
        sales
    GROUP BY vehicle_category) AS analysis
ORDER BY pct_increase DESC; 

-- vehicle_class analysis
WITH t AS 
(
	SELECT 
		vehicle_class, 
        SUM(EV_sales_quantity) as total_sales,
		ROUND(SUM(EV_sales_quantity) * 100.0 / SUM(SUM(EV_sales_quantity)) OVER(), 2) AS pct_sales
	FROM sales 
	GROUP BY vehicle_class
)
SELECT * FROM t 
	WHERE pct_sales > 0
	ORDER BY total_sales DESC; 

-- sales forecast based on moving average 
SELECT 
	year, 
	SUM(EV_sales_quantity) as total_sales, 
	(
		CASE 
		WHEN YEAR > 2014 THEN 
		ROUND(AVG(SUM(EV_sales_quantity)) OVER(ORDER BY year ROWS BETWEEN 1 PRECEDING AND CURRENT ROW), 2)
    ELSE NULL 
    END
)
	AS moving_avg
FROM sales
GROUP BY year;

-- environmental impact assessment 
SELECT 
    vehicle_category,
    SUM(EV_sales_quantity) AS total_sales,
    ROUND(SUM(CASE
                        WHEN vehicle_category = '4-Wheelers' THEN EV_sales_quantity * 2.3
                        WHEN vehicle_category = '2-Wheelers' THEN EV_sales_quantity * 0.4
                        WHEN vehicle_category = '3-Wheelers' THEN EV_sales_quantity * 1.2
                        WHEN vehicle_category = 'Bus' THEN EV_sales_quantity * 20
                        ELSE EV_sales_quantity * 1
                    END),
            2) AS estimated_co2_savings_MT
FROM
    sales
GROUP BY vehicle_category
ORDER BY estimated_co2_savings_MT DESC;

-- 3-wheelers details 
SELECT 
    state,
    vehicle_class,
    SUM(EV_sales_quantity) AS total_sales,
    ROUND(SUM(EV_sales_quantity) * 1.2, 2) AS co2_savings
FROM
    sales
WHERE
    vehicle_category = '3-Wheelers'
GROUP BY state , vehicle_class
HAVING SUM(EV_sales_quantity) > 1
ORDER BY co2_savings DESC;
