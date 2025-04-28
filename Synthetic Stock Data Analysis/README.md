# Synthetic Stock Data Analysis

## Overview  
This project presents a comprehensive SQL analysis of **stock market data across multiple companies and sectors** from synthetic daily trading data. It explores **price trends, volatility, sentiment, dividends, and sector comparisons** using advanced SQL techniques.

## Schema & Data  
The dataset consists of a single main table:

### `synthetic_stock_data`  
| Column Name       | Description                                          |
|-------------------|------------------------------------------------------|
| `company`         | Name of the company                                  |
| `sector`          | Industry sector                                     |
| `date`            | Trading date                                        |
| `open`            | Opening stock price                                 |
| `close`           | Closing stock price                                 |
| `high`            | Highest price during the day                        |
| `low`             | Lowest price during the day                         |
| `volume`          | Number of shares traded                             |
| `market_cap`      | Market capitalization                               |
| `sentiment_score` | Market sentiment score based on news/social data   |
| `dividend_yield`  | Dividend yield percentage                           |
| `PE_Ratio`        | Price-to-Earnings ratio                             |

## Analysis & Key Insights  
Using SQL window functions, joins, conditional logic, and time-series analysis, the queries uncover:

- Company and sector volatility and rankings  
- Price momentum and consecutive gains  
- Volume trends across years and months  
- Relationships between sentiment scores and dividend yields  
- Sector drawdowns and average price movements  
- Earnings per share estimation and volatility variations  

These provide a clear picture of market behavior, company performance, and sector risk.

## Skills Used  
- SQL Common Table Expressions (CTEs)  
- Window Functions & Joins
- CASE statements for conditional logic  
- Aggregations and conditional aggregations  
- Time-series analysis using date functions (YEAR, MONTH, DATE_ADD)  
- Ranking and partitioning for comparative analytics  
- Portfolio valuation and dividend yield analysis  

## Author  
Supreet Dodani 
[LinkedIn](https://www.linkedin.com/in/supreet-dodani-3a3371246/)
