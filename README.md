Food Analysis

A complete data analytics project that transforms fragmented food-retail data into actionable business insights using SQL Server, SQL, DAX, and Power BI.

The project builds an end-to-end analytical workflow: raw CSV files are cleaned and enriched, loaded into a structured Snowflake Schema, analyzed with SQL, and presented through an interactive Power BI dashboard.


Project team: Karim Abdelaziz, Lobna Ashraf, Ashrakat Mohsen, and Rania Essam
Organization / Track: Route




Table of Contents

•
Project Overview

•
Business Problem

•
Business Questions

•
Data Sources

•
Project Workflow

•
Data Model

•
Technologies

•
Analysis Performed

•
Power BI Dashboard

•
Key Insights

•
Repository Structure

•
How to Use

•
Future Improvements

•
Team




Project Overview

Food Analysis is designed to help leadership understand sales performance, profitability, customer behavior, product health categories, store efficiency, and return patterns across regions and time periods.

The solution provides a centralized reporting layer where business users can monitor standardized KPIs instead of relying on fragmented and inconsistent reports.




Business Problem

The business operates across multiple regions and generates large volumes of sales, product, customer, store, and return data. Before this project, the data was distributed across different files, making it difficult to:

•
Standardize business KPIs.

•
Compare regional and store performance.

•
Identify the products and stores driving returns.

•
Understand customer value and behavior.

•
Track profitability over time.

•
Give decision-makers a reliable view of performance drivers.

Objective

Build a centralized, data-driven analytics solution that improves visibility into business performance and supports better growth decisions.




Business Questions

The project answers questions such as:

1.
What is the net sales performance by region?

2.
Which products have unusually high return rates?

3.
How do monthly sales evolve for each store?

4.
Do older stores outperform newer stores?

5.
Who are the highest-value customers?

6.
Do low-fat products generate higher sales or lower return rates?

7.
Which stores contribute most to profitability?

8.
How do customer income, age, membership, and family characteristics relate to revenue?




Data Sources

The analysis starts with CSV files containing sales, product, customer, and return-related information. The main source files presented in the project include:

•
Sales_1997.csv

•
Sales_1998.csv

•
Product.csv

•
Customer information

•
Store and region information

•
Return information


File names may vary in the repository. Update this section if the actual filenames are different.




Project Workflow

Plain Text


Raw CSV Files
     │
     ▼
Extract
     │  Load sales, product, customer, store, region, and return data
     ▼
Transform
     │  Clean, merge, enrich, classify, and prepare analytical attributes
     ▼
Load
     │  Store the modeled data in SQL Server
     ▼
SQL Analysis
     │  Explore trends, profitability, returns, and customer value
     ▼
DAX Measures
     │  Create business KPIs and time-intelligence calculations
     ▼
Power BI Dashboard
        Communicate insights through interactive reports



Data Transformation

The transformation layer includes:

•
Cleaning and standardizing raw data.

•
Merging names and descriptive attributes.

•
Calculating customer age and store/customer tenure where applicable.

•
Creating customer income segments:

•
Low income

•
Medium income

•
High income



•
Creating product flags and categories:

•
Recyclable / non-recyclable

•
Low-fat / non-low-fat

•
Healthy / not healthy



•
Preparing fact and dimension tables for reporting.




Data Model

The project uses a Snowflake Schema with sales and returns as central fact tables and descriptive dimensions surrounding them.

mermaid

Source



Main Tables

Table
Type
Purpose
FactSales
Fact
Sales transactions, revenue, and units sold
FactReturns
Fact
Returned units and return activity
DimCustomers
Dimension
Customer demographics, income, membership, and segments
DimCalendar
Dimension
Date, month, quarter, and year analysis
DimProducts
Dimension
Product descriptions and product classifications
DimStores
Dimension
Store details, country, and store performance attributes
DimRegion
Dimension
Regional grouping and geographic analysis







Technologies

•
SQL Server — Data warehouse storage and database operations.

•
SQL — Data loading, transformation, exploration, aggregation, and business analysis.

•
DAX — Power BI measures and time-intelligence calculations.

•
Power BI — Interactive dashboards and business reporting.

•
CSV — Initial source-data format.




Analysis Performed

Sales and Financial Analysis

•
Transaction counts and summary statistics.

•
Daily, monthly, quarterly, and yearly sales trends.

•
Net revenue and gross profit analysis.

•
Year-over-year profit and revenue growth.

•
Average Order Value (AOV).

•
Store profitability and store profit per square foot.

Returns Analysis

•
Overall return ratio.

•
Return rates by store and country.

•
Top returned products.

•
Monthly return trends.

•
Identification of stores with unusually high return activity.

Customer Analysis

•
RFM analysis:

•
Recency — How recently a customer purchased.

•
Frequency — How often a customer purchased.

•
Monetary — How much a customer spent.



•
Customer segmentation by income.

•
Analysis by age group, member card, and number of children.

•
Identification of high-value customer groups.

Product and Store Analysis

•
Product segmentation by price level.

•
Healthy vs. not healthy product analysis.

•
Low-fat product performance.

•
Recyclable product classification.

•
Store comparison by revenue, profit, efficiency, and returns.




Power BI Dashboard

The dashboard is organized into specialized analytical pages:

1. Overview

Provides a high-level view of business performance through KPI cards, yearly revenue trends, and customer-status analysis.

Highlighted KPIs from the project presentation:

•
Net Revenue: approximately $1.75M

•
Gross Profit: approximately $1.04M

•
Units Sold: approximately 833K

2. Time Analysis

•
Daily sales trends.

•
Monthly sales performance.

•
Financial loss by month.

•
Year-over-year comparisons.

3. Returns

•
Return rates by store.

•
Top returned products.

•
Return trends by store country.

•
Store-level return investigation.

4. Customer Analysis

•
Customer segmentation by member card.

•
Income-group analysis.

•
Age-group revenue comparison.

•
Family and demographic analysis.

5. Stores and Products

•
Store performance maps.

•
Store-efficiency charts.

•
Product segmentation.

•
Healthy vs. not healthy product comparison.

•
Cheap vs. high-end product analysis.

Key DAX Measures

The model includes measures such as:

•
Net Revenue

•
Gross Profit

•
Sales YTD

•
Return Ratio

•
YoY Profit Growth

•
Average Order Value (AOV)




Key Insights

The project presentation highlights the following findings:

•
Revenue increased from approximately $548K in 1997 to $1.18M in 1998, representing growth of more than 100%.

•
A small group of stores, including Stores 13, 17, and 15, contributes disproportionately to profitability.

•
Medium-income customers with income between approximately $40K and $80K generate the highest revenue.

•
Customers with no children are among the strongest revenue contributors.

•
Customers aged 60+ and 40–49 are major revenue-driving age groups.

•
Approximately 64% of products are categorized as Not Healthy.

•
The overall return rate is approximately 1%, but Stores 8 and 20 show comparatively higher return activity and should be investigated.


Dashboard values can change depending on the final data refresh, filters, and model version.




Repository Structure

A recommended repository structure is:

Plain Text


Food-Analysis/
├── data/
│   ├── Sales_1997.csv
│   ├── Sales_1998.csv
│   ├── Product.csv
│   └── Customer.csv
├── sql/
│   ├── 01_create_database.sql
│   ├── 02_create_tables.sql
│   ├── 03_load_data.sql
│   └── 04_analysis_queries.sql
├── power-bi/
│   └── Food-Analysis.pbix
├── images/
│   └── dashboard-preview.png
└── README.md



Adjust the structure above to match the actual files in the repository.




How to Use

Prerequisites

•
SQL Server

•
SQL Server Management Studio or Azure Data Studio

•
Power BI Desktop

•
Access to the project CSV files

Suggested Setup

1.
Clone the repository:

Bash


git clone https://github.com/<your-username>/<your-repository>.git
cd <your-repository>





2.
Place the source CSV files in the project data directory.

3.
Run the SQL scripts in the following order:

1.
Create the database.

2.
Create the fact and dimension tables.

3.
Load and transform the source data.

4.
Run the analysis queries.



4.
Open the Power BI file.

5.
Update the SQL Server connection if required.

6.
Refresh the model and explore the dashboard pages.


Replace the placeholder repository URL and script names with the real project links before publishing.




Future Improvements

•
Add automated data-refresh pipelines.

•
Include data-quality checks and validation rules.

•
Add forecasting for sales and returns.

•
Build a dedicated customer-lifetime-value model.

•
Add row-level security for regional managers.

•
Track dashboard usage and KPI adoption.

•
Publish a live Power BI Service workspace.




Team

•
Karim Abdelaziz

•
Lobna Ashraf

•
Ashrakat Mohsen

•
Rania Essam

