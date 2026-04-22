\# Azure Medallion Data Pipeline: Water Quality Analysis



This project builds an end-to-end data engineering pipeline to process large sensor water quality data collected across European countries, starting from getting the raw data in a managed SQL database and ends with consumable insight on a Power BI dashboard. We used Azure services. We implemented Medallion Architecture (Bronze, Silver, and Gold layers) to analyze historical water sensor data



\## Architecture Overview

The data pipeline orchestrates data flow through the following stages:

1. Ingestion: Raw data in Excel files is loaded into Azure SQL Database
2. Movement: Azure Logic Apps wait for new data and store it in Azure Blob Storage as JSON. This becomes the central hub from where any product can read this data and also acts as a backup for the Azure SQL database
3. Orchestration: Azure Data Factory moves data from Blob storage to Azure Data Lake Gen2. Here data is ready to be process by Databricks
4. Transformations: Azure Databricks process data using Spark through three layers as follows: 

&#x20;  - Bronze: Raw data ingestion.

&#x20;  - Silver: Data cleaning, filtering, and schema refinement

&#x20;  - Gold: Outlier detection (Z-Score) and creation of a Water Quality Index (WQI)

5\. Visualization: Final curated data is visualized in Power BI



\## Tech Stack

\- Cloud: Microsoft Azure (SQL DB, Logic Apps, ADF, ADLS Gen2, Databricks)

\- Infrastructure as Code: Terraform

\- Languages: SQL, Python/PySpark, DAX

\- BI Tool: Power BI



\## Highlights:

1. We implemented Medallion Architecture that is best suited for government audits and it progressively improves data quality
2. We utilized Z-score in the gold layer to identify environmental outliers
3. We developed custom DAX measures to calculate a normalized index for determinants across multiple countries



\## Repo Structure

\- Project\_Code: Contains the Jupyter/Databricks notebooks for the Medallion layers

\- Installation+\&+Execution: Contains the Power BI `.pbix` dashboard and DAX formulas

\- Terraform: Infrastructure as Code files to deploy the required Azure services

