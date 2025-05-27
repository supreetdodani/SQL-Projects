/* 		Agenda of the project: 
		To analyze industries based on how they have been impacted by the recent boom of AI.
        To look at the popularity of each of the 7 AI tools present in the dataset. 
		The project also briefly looks at how AI has affected employment & revenue across countries & industries.
*/

-- market share for each industry
SELECT industry, ROUND(AVG(Consumer_Trust_rate), 2) as consumer_trust, 
ROUND(AVG(market_share), 2) as avg_market_share_for_ai_tools, rank() OVER(ORDER BY AVG(market_share) DESC) as rnk
FROM ai_impact
GROUP BY industry
ORDER BY rnk;

/* 
	Given the output, we can gather that the highest AI tools are used within Media as an industry
*/ 

-- market share for each ai_tool 
SELECT ai_tools, ROUND(AVG(Consumer_Trust_rate), 2) as consumer_trust, 
ROUND(AVG(market_share), 2) as avg_market_share, rank() OVER(ORDER BY AVG(market_share) DESC) as rnk
FROM ai_impact
GROUP BY ai_tools
ORDER BY rnk;

  
/* 
	Stable Diffusion has the highest market share amongst the 7 tools.
    Bard, with the least market share, has the highest consumer trust rate in the market. 
*/ 

-- market share for each tool ranked on year to determine the the tools' highest market share for each year. 
WITH rnks AS (SELECT ai_tools, rank()OVER(ORDER BY AVG(market_share) DESC) as tool_rnk
			  FROM ai_impact
              GROUP BY ai_tools)

SELECT 
	a.ai_tools, b.year, 
    ROUND(AVG(b.market_share), 2) as avg_market_share, 
    rank() OVER(PARTITION BY b.year ORDER BY AVG(b.market_share) DESC) as yearly_rnk,
    tool_rnk
FROM rnks a
LEFT JOIN ai_impact b
ON a.ai_tools = b.ai_tools 
GROUP BY a.ai_tools, b.year
ORDER BY tool_rnk, yearly_rnk; 

/* 
	Stable Diffusion has the highest overall market share amongst the 7 tools.
    Bard, with the least market share, has the highest consumer trust rate in the market. 
	
    Stable Diffusion had the highest market shares for 3 consecutive years(with a decreasing rate), with Bard overtaking it in 2023. 
    The tool then moved down to the 7th rank in  2023 and up to 6th in 2024.
    Interestingly, the tool has the highest market share again in 2025. 
    
    Key Insight: Starting from 2020, stable diffusion had a stable market share.
    The boom of AI in the recent years has increase competition for Stable Diffusion. 
    However, it's return to the highest market share holder in 2025 indicates that the tool is moving with the needs of the hour. 

*/ 

-- top performance year for each company based on the market_share ranked on their total market share. 
WITH rnks AS (SELECT ai_tools, ROUND(AVG(market_share), 2) as avg_market_share, 
			  rank() OVER(ORDER BY AVG(market_share) DESC) as rnk
			  FROM ai_impact 
              GROUP BY ai_tools), 
	
    country_split AS (SELECT ai_tools, Year, ROUND(AVG(market_share), 2) as avg_market_share
					  FROM ai_impact 
                      GROUP BY ai_tools, Year)
					
SELECT ai_tools, year, avg_market_share, total_rnk
FROM (
		SELECT 
		cs.ai_tools, cs.year, cs.avg_market_share, r.rnk as total_rnk, 
		RANK() OVER(PARTITION BY ai_tools ORDER BY avg_market_share DESC) as year_wise_rank
		FROM country_split cs
		JOIN rnks r 
		ON cs.ai_tools = r.ai_tools
		ORDER BY r.rnk, cs.avg_market_share DESC
    ) a 
WHERE year_wise_rank = 1;

-- country-wise split of the market share of each ai_tool, ranked based on their respective market shares & performance in each country.
WITH rnks AS (SELECT ai_tools, ROUND(AVG(market_share), 2) as avg_market_share, 
			  rank() OVER(ORDER BY AVG(market_share) DESC) as rnk
			  FROM ai_impact 
              GROUP BY ai_tools),  
	
    country_split AS (SELECT ai_tools, country, ROUND(AVG(market_share), 2) as avg_market_share
					  FROM ai_impact 
                      GROUP BY ai_tools, country)
					
SELECT 
	cs.country, cs.ai_tools, cs.avg_market_share, r.rnk as total_rank, 
	rank() OVER(PARTITION BY country ORDER BY avg_market_share DESC) as country_wise_rank
FROM country_split cs 
JOIN rnks r 
	ON cs.ai_tools = r.ai_tools
ORDER BY country, cs.avg_market_share DESC;

 -- market share compared with AI adoption rate
SELECT 
	ai_tools, 
	ROUND(AVG(market_share), 2) as avg_market_share, 
    ROUND(AVG(ai_adoption_rate), 2) as ai_adoption_rate
FROM ai_impact
GROUP BY ai_tools
ORDER BY avg_market_share DESC;

/* 
	Stable Diffusion has the highest market share, meanwhile ChatGPT has the highest adoption rate. 
*/ 
	
-- market sentiment analysis based on the regulation status of each industry per year
WITH regulatory_analysis AS (SELECT year, country, ai_tools, industry, regulation_status, 
							ROUND(AVG(consumer_trust_rate), 2) as consumer_trust_rate, 
							CASE WHEN regulation_status = 'Strict' THEN -1 
								 WHEN regulation_status = 'Moderate' THEN 0 
								 WHEN regulation_status = 'Lenient' THEN 1
								 END 
									AS regulation_score
							FROM ai_impact 
							GROUP BY country, ai_tools, year, industry, regulation_status)

SELECT year, industry, market_sentiment, COUNT(*) as count FROM (
SELECT year, country, ai_tools, industry, market_sentiment
FROM (SELECT year, industry, country, ai_tools, regulation_status, regulation_sentiment,
	  CASE 
			WHEN regulation_sentiment > 0 THEN 'positive'
			WHEN regulation_sentiment = 0 THEN 'neutral'
			ELSE 'negative' 
			END as market_sentiment
			FROM (
				  SELECT year, country, ai_tools, industry, SUM(regulation_score) as regulation_sentiment, regulation_status
				  FROM regulatory_analysis
                  GROUP BY year, country, ai_tools, industry, regulation_status) a
			) b
GROUP BY year, industry, market_sentiment, country, ai_tools
ORDER BY year) c
GROUP BY year, industry, market_sentiment
ORDER BY count DESC, year, industry;

-- year on year comparison of job loss and AI adoption per industry
WITH CTE AS (
			SELECT 
				industry, year, 
				ROUND(AVG(job_loss_to_AI_rate), 2) as job_loss, 
				ROUND(AVG(AI_adoption_rate), 2) as ai_adoption
			FROM ai_impact
            GROUP BY industry, year), 
            
	CTE2 AS (
			SELECT industry, 
            IFNULL(LAG(year) OVER(PARTITION BY industry ORDER BY year), 0) as previous_year, 
			IFNULL(LAG(job_loss) OVER(PARTITION BY industry ORDER BY year), 0) as previous_job_loss,
			IFNULL(LAG(ai_adoption) OVER(PARTITION BY industry ORDER BY year), 0) as previous_ai_adoption, 
			year as current_year, 
			job_loss as current_job_loss,
			ROUND(SUM(job_loss) OVER(PARTITION BY industry ORDER BY year), 2) as running_total_job_loss,
			ai_adoption as current_ai_adoption, 
			ROUND(SUM(ai_adoption) OVER (PARTITION BY industry ORDER BY year), 2) as running_total_ai_adoption
        FROM CTE) 
        
SELECT * 
	FROM CTE2 a
	WHERE NOT EXISTS (SELECT 1 FROM CTE2 b WHERE b.previous_year = 0 
					  AND b.previous_job_loss = 0
					  AND b.industry = a.industry
					  AND b.current_year = a.current_year);
	
-- job loss rate versus revenue increase rate per industry ranked within each year
SELECT * FROM (SELECT 
	year, industry, job_loss, ai_adoption, 
    rank() OVER(PARTITION BY year ORDER BY job_loss DESC) as job_loss_rnk, 
    revenue_increase, 
	rank() OVER(PARTITION BY year ORDER BY revenue_increase DESC) as revenue_increase_rnk
FROM (
		SELECT year, industry, 
        ROUND(AVG(revenue_increase_due_to_AI_rate), 2) as revenue_increase, 
        ROUND(AVG(Job_Loss_to_AI_rate), 2) as job_loss,
        ROUND(AVG(AI_adoption_rate), 2) as ai_adoption
        FROM ai_impact
        GROUP BY year, industry) AS b ) as c 
WHERE job_loss_rnk = (SELECT max(job_loss_rnk) 
						FROM (SELECT year, industry, 
                        rank() OVER(partition by year ORDER BY AVG(job_loss_to_AI_rate) DESC) 
                        FROM ai_impact 
                        GROUP BY year, industry
                        )
                        as d 
                        WHERE d.year = c.year)
ORDER BY job_loss DESC; 

/* 
	Highest job loss overall was within the Retail industry at 49.58%, also having the least revenue increase of 1.75% and a below average AI adoption rate. 
*/

-- AI Tools that led to the most job loss and revenue creation per industry
SELECT 
	ai_tools, industry, 
    ROUND(AVG(job_loss_to_AI_rate), 2) as job_loss, 
	ROUND(AVG(revenue_increase_due_to_AI_rate), 2) as revenue_creation, 
    row_number() OVER(partition by industry order by AVG(job_loss_to_AI_rate) DESC) as job_loss_rnk, 
    row_number() over(partition by industry order by AVG(revenue_increase_due_to_AI_rate) DESC) as revenue_creation_rnk
FROM ai_impact 
GROUP BY ai_tools, industry
ORDER BY industry, job_loss DESC, revenue_creation DESC; 

/* 
	Stable Diffusion ranks 1 in various industries, keeping in line with the AI tool being the highest market share holder from the	 	analysis above. 
*/

-- Percent of AI tools replacing the human workforce within diff industries & countries
SELECT industry, ROUND(avg(revenue_increase_due_to_AI_rate), 2) as revenue_increase,
ROUND(avg(Job_Loss_to_AI_rate), 2) as job_loss, ROUND(avg(ai_adoption_rate),2) as ai_adoption, 
COALESCE(NULLIF(ROUND(percent_rank() OVER(ORDER BY AVG(ai_adoption_rate) DESC), 2), 0), 'NA') as percent_rnk
FROM ai_impact
GROUP BY industry
ORDER BY job_loss DESC;

/* 
	Key Insight: AI is replacing human workforce across industries with AI_adoption rates as high as ~60%.
*/

-- years & industries in which revenue and job loss had a positive increasing correlation 
WITH YoY_ai_adoption AS (SELECT year as current_year, industry, ROUND(AVG(AI_adoption_rate), 2) as current_ai_adoption, 
								LAG(year) OVER(PARTITION BY industry ORDER BY year) as previous_year, 
                                ROUND(LAG(AVG(AI_adoption_rate)) OVER(PARTITION BY industry ORDER BY year), 2) as previous_ai_adoption
								FROM ai_impact 
								GROUP BY year, industry), 
	increasing_ai_adoption AS(SELECT current_year, industry, current_ai_adoption, previous_year, previous_ai_adoption
							  FROM YoY_AI_adoption 
                              WHERE current_ai_adoption > previous_ai_adoption 
                              AND CONCAT(current_year, '-01-01') = DATE_ADD(CONCAT(previous_year, '-01-01'), INTERVAL 1 YEAR)), 
	YoY_revenue_creation AS (SELECT year as current_year, 
							 industry, 
                             ROUND(AVG(revenue_increase_due_to_AI_rate), 2) as current_revenue_increase, 
                             LAG(year) OVER(PARTITION BY industry ORDER BY year) as previous_year, 
                             ROUND(LAG(AVG(revenue_increase_due_to_AI_rate)) OVER(PARTITION BY industry ORDER BY year), 2) as previous_revenue_increase
                             FROM ai_impact
                             GROUP BY year, industry), 
	increasing_revenue AS (SELECT current_year, industry, current_revenue_increase, previous_year, previous_revenue_increase
						   FROM YoY_revenue_creation
                           WHERE current_revenue_increase > previous_revenue_increase 
                           AND CONCAT(current_year, '-01-01') = DATE_ADD(CONCAT(previous_year, '-01-01'), INTERVAL 1 YEAR))
                           
SELECT 
	ia.industry, ia.current_year, ir.current_revenue_increase, ia.current_ai_adoption, 
    ia.previous_year, ir.previous_revenue_increase, ia.previous_ai_adoption, ROUND(AVG(impact.job_loss_to_AI_rate), 2) as job_loss, 
    ROUND(AVG(human_AI_collaboration_rate), 2) as human_ai_collab,
	ROUND(100 * (current_revenue_increase - previous_revenue_increase)/ NULLIF(previous_revenue_increase, 0), 2) as percent_revenue_increase
FROM increasing_ai_adoption ia
JOIN increasing_revenue ir
	ON ia.current_year = ir.current_year
	AND ia.industry = ir.industry 
JOIN ai_impact impact 
	ON impact.industry = ia.industry
	AND impact.year = ia.current_year
GROUP BY ia.industry, ia.current_year, ir.current_revenue_increase, ia.current_ai_adoption, 
		 ia.previous_year, ir.previous_revenue_increase, ia.previous_ai_adoption
ORDER BY ia.current_year, ia.industry;

SELECT industry, length(industry)
FROM ai_impact
WHERE length(industry) = (SELECT MAX(length(industry)) FROM ai_impact) 
GROUP BY industry;

/* 
	Key Insight: Trendlines are moving differently for different industries. While some industries are relying heavily on AI, with increasing AI revenue, job losses and minimal human-AI collboration, other industries are using AI tools to enhance their workforce, evident by the increasing Human-AI collaborations. 
    However, in totality, we see a general shift towards more reliance on AI tools, as reflected in the high job loss rates and the revenue increases due to AI. 
