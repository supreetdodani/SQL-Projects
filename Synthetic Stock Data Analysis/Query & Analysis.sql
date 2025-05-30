-- second highest daily high for each sector
WITH ranks as (
				SELECT 
					company,sector, market_cap, sentiment_score, Trend, High, 
					RANK() OVER(PARTITION BY sector ORDER BY High DESC) as rnk
                FROM 
					synthetic_stock_data
                    ) 
                
SELECT * 
	FROM 
		ranks
	WHERE rnk = 2;

-- average closing price for each stock 
SELECT 
    company, sector, ROUND(AVG(close), 2) AS average_closing
FROM
    synthetic_stock_data
GROUP BY company , sector;

-- highest closing price per company
SELECT 
    company, ROUND(MAX(close),2) AS highest_closing
FROM
    synthetic_stock_data
GROUP BY company;

-- total trading volume 
SELECT 
    company, SUM(volume) AS trading_volume
FROM
    synthetic_stock_data
GROUP BY company;

-- stocks exhibiting the highest average daily volatility
SELECT 
    company, ROUND(AVG(high - low), 2) AS volatility
FROM
    synthetic_stock_data
GROUP BY company;

-- uber exhibits the highest daily volatility 

-- 7 Day moving average for uber
SELECT 
	date, 
	ROUND(AVG(close) OVER(PARTITION BY company ORDER BY date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),2) 
		as moving_avg
FROM 
	synthetic_stock_data
WHERE 
	company = 'Uber';

-- companies that had consecutive days of price increases
SELECT 
    a.company,
    a.date AS current_day,
    a.open as today_open,
    b.date AS previous_day,
    b.open as previous_open
FROM
    synthetic_stock_data a
        JOIN
    synthetic_stock_data b ON a.Date = DATE_ADD(b.Date, INTERVAL 1 DAY)
        AND a.company = b.company
WHERE
    a.open > b.open;

-- volatility based on the sector in 2024
SELECT 
	sector, 
    ROUND(AVG(high-low), 2) as avg_volatility,
	DENSE_RANK() OVER(ORDER BY AVG(high-low) ASC) as ranking 
FROM 
	synthetic_stock_data
WHERE 
	YEAR(date) = 2024
GROUP BY 
	sector
ORDER BY 
	avg_volatility ASC;

-- the consumer goods sector is the least volatile, whereas the Automotive industry exhibits the most volatility

-- 10 companies with the least volatility within the consumer goods, aerospace & energy sector[least 3 volatile]
WITH ranks AS 
	(
		SELECT 
			company, 
			sector, 
			ROUND(AVG(high-low), 2) as avg_volatility, 
			DENSE_RANK() OVER(PARTITION BY sector ORDER BY AVG(high-low) ASC) as ranking
		FROM 
			synthetic_stock_data
		WHERE 
			YEAR(date) = 2024
		AND 
			sector IN ('consumer goods', 'aerospace', 'energy')
		GROUP BY 
	company, sector
		ORDER BY 
	sector, avg_volatility ASC
    ) 

SELECT * FROM ranks 
WHERE ranking <= 10;

-- OR (based on the sector ranks) 

WITH sector_rank AS 
(
	SELECT 
		sector, 
        ROUND(AVG(high-low), 2) as avg_volatility,
		DENSE_RANK() OVER(ORDER BY AVG(high-low) ASC) as ranking 
	FROM 
		synthetic_stock_data
	WHERE 
		YEAR(date) = 2024
	GROUP BY sector
	ORDER BY avg_volatility ASC
    ), 

company_rank AS 
(
	SELECT 
		company, 
		sector, 
		ROUND(AVG(high-low), 2) as avg_volatility, 
		DENSE_RANK() OVER(PARTITION BY sector ORDER BY AVG(high-low) ASC) as ranking
	FROM 
		synthetic_stock_data
	WHERE 
		YEAR(date) = 2024
  AND sector IN ('consumer goods', 'aerospace', 'energy')
	GROUP BY 
		company, sector
	ORDER BY 
		sector, avg_volatility ASC
	)

SELECT
	cr.company, 
    cr.sector, 
    cr.avg_volatility, 
    cr.ranking
FROM 
	company_rank cr 
		JOIN 
sector_rank sr
		ON 
cr.sector = sr.sector 
WHERE 
	cr.ranking <=10
ORDER BY 
	sr.ranking ASC, cr.ranking ASC;

-- drawdown percent for each sector 
WITH drawdown AS 
	(
		SELECT 
			sector, 
            year(date) as year,
            AVG(high) as high, 
            AVG(low) as low
		FROM 
			synthetic_stock_data
		GROUP BY 
			sector, year
		)
SELECT 
    sector,
    year,
    ROUND((high - low) * 100 / low, 4) AS percent_increase
FROM
    drawdown
WHERE year NOT IN (2022)
ORDER BY 
	sector ASC, year ASC, percent_increase ASC; 
    
-- close price greater than previous day close price
WITH comparison AS 
				(
					SELECT 
						company, sector, 
						LAG(date) OVER(ORDER BY DATE ASC) as previous_day,
						ROUND(LAG(close) OVER(ORDER BY DATE ASC), 4) as previous_close,
						date as current_day, ROUND(close, 4) as current_close
                    FROM 
						synthetic_stock_data
					) 
SELECT 
	company, 
	previous_day, 
	previous_close, 
	current_day, 
	current_close
FROM 
	comparison 
		WHERE current_close > previous_close 
		AND current_day = DATE_ADD(previous_day, INTERVAL 1 DAY); 

-- number of consecutive days where current_close > previous_close[strength]
WITH comparison AS 
				(
					SELECT 
						company, sector, 
						LAG(date) OVER(ORDER BY DATE ASC) as previous_day,
						ROUND(LAG(close) OVER(ORDER BY DATE ASC), 4) as previous_close,
						date as current_day, 
						ROUND(close, 4) as current_close
					FROM 
						synthetic_stock_data
					) 
SELECT company, 
	SUM(IF((current_close>previous_close), 1, 0)) as num_days,
	DENSE_RANK() OVER(ORDER BY SUM(IF((current_close>previous_close), 1, 0)) DESC) as 'rank' 
FROM 
	comparison
GROUP BY company;

/** Panasonic exhibits the highest strength based on the previous query
Hence, I will be analyzing the volume for panasonic for each year and month below to determine 
the month in which it's volume was maximum and in which year**/ 
    
-- yearly ranking based on volume 
SELECT 
	company, 
	year(date) as year, 
    MAX(volume) as highest_volume,
	RANK() OVER(PARTITION BY company ORDER BY MAX(volume) DESC) as 'rnk'
FROM synthetic_stock_data
WHERE company ='panasonic'
	GROUP BY company, year
	ORDER BY company; 

-- performance by volume based on year & months
SELECT 
	company, 
    year(date) as year, 
    month(date) as month, 
    MAX(volume) as highest_volume,
	RANK() OVER(PARTITION BY company, year(date) ORDER BY MAX(volume) DESC) as 'rnk'
FROM synthetic_stock_data
WHERE company = 'panasonic' 
	GROUP BY company, year, month
	order by highest_volume DESC; 

/** NOTE:
AVG dividend yielded by companies with a positive sentiment score (>=0.5) is 2.5818 
AVG dividend yielded by companies with a neutral & negative sentiment score(<0.5) is 2.5414**/ 

-- companies with negative market sentiment but a high dividend yield
SELECT 
   *
FROM
    (SELECT 
        company,
            year,
            sentiment_score,
            market_sentiment,
            dividend_yield,
            CASE
                WHEN dividend_yield > 2.5818 THEN 'high yield'
                WHEN dividend_yield BETWEEN 2.5414 AND 2.5818 THEN 'neutral'
                WHEN dividend_yield < 2.5414 THEN 'low yield'
            END AS dividend_status
    FROM
        (SELECT 
        company,
            YEAR(date) AS year,
            ROUND(AVG(sentiment_score), 4) AS sentiment_score,
            ROUND(AVG(Dividend_Yield), 4) AS dividend_yield,
            CASE
                WHEN AVG(sentiment_score) BETWEEN 0.5 AND 1 THEN 'very positive'
                WHEN AVG(Sentiment_Score) BETWEEN 0.1 AND 0.5 THEN 'positive'
                WHEN AVG(Sentiment_Score) BETWEEN - 0.1 AND 0.1 THEN 'Neutral'
                WHEN AVG(sentiment_score) BETWEEN - 0.1 AND - 0.5 THEN 'Negative'
                ELSE 'Very Negative'
            END AS market_sentiment
    FROM
        synthetic_stock_data
    GROUP BY company , year) as b ) AS a
    WHERE market_sentiment IN ('negative', 'very negative') 
    AND dividend_status IN ('neutral','high yield')
ORDER BY dividend_yield DESC, sentiment_score; 

-- companies whose sentiment score increased along with their dividend yield on a quarterly basis 
WITH dividends as (SELECT 
	a.company,
    year(a.date) as year,
    month(a.date) as current_month,
    ROUND(a.sentiment_score, 4) as current_sentiment, 
	ROUND(a.dividend_yield, 4) as current_dividend,
    year(b.date) as p_year,
    month(b.date) as previous_month,
	ROUND(IFNULL(LAG(a.sentiment_score) OVER(PARTITION BY company ORDER BY a.date), b.sentiment_score), 4) as previous_sentiment,
	ROUND(IFNULL(LAG(a.dividend_yield) OVER(PARTITION BY company ORDER BY a.date), b.dividend_yield), 4) as previous_dividend
FROM 
	synthetic_stock_data a
JOIN 
	synthetic_stock_data b
ON 
	a.company = b.company 
WHERE 
	a.Sentiment_Score > b.sentiment_score 
	AND a.date = DATE_ADD(b.date, INTERVAL 1 quarter)
	AND a.dividend_yield > b.dividend_yield
GROUP BY 
	company, a.date, b.date, a.Sentiment_Score, a.dividend_yield, b.Dividend_Yield, b.sentiment_score)
    
SELECT company, year, current_month, current_sentiment, current_dividend, p_year, previous_month, previous_sentiment, previous_dividend, 
ROUND((current_dividend - previous_dividend), 2) as percent_increase
FROM dividends;
    
/** INSIGHTS
1. Citigroup's sentiment jumped to 0.72 in September 2022 from -0.45 in June 2022, reflected in the 3.6% increase in it's dividend.  
2. While Ford's sentiment has remained stagnant, it's dividend increased by 2%
3. Overall, we can observe that there is a disproportionate relationship between sentiment score & dividend. 
**/

-- EPS [higher the better]
SELECT
	company, 
    year(date) as year, 
    ROUND(AVG(open)/AVG(PE_Ratio), 4) as EPS
FROM 
	synthetic_stock_data
GROUP BY 
	company, year;

-- volatility tracker based on standard deviation [lower the better]
SELECT 
	company, 
	date, 
    STDDEV(volatility) OVER(PARTITION BY company ORDER BY date ROWS BETWEEN 13 PRECEDING AND CURRENT ROW) 
	as volatility_variation 
FROM 
	synthetic_stock_data;
