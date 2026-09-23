# ipo-listing-performance-analysis

Data analyst project on 5 years of Indian IPO listings (2020-2025) — Python, MySQL & Power BI. Cleaning, EDA, stats, ML, and an interactive dashboard.

**Author:** Ishwari Gurde, B.Tech graduate (Electronics & Telecommunication Engineering)

---

## Overview

This project analyzes 4,256 IPOs listed on Indian exchanges (Mainboard and SME) between September 2020 and September 2025. It covers the full data analyst workflow: cleaning messy raw data, engineering new features, exploratory data analysis, statistical testing, a simple prediction model, SQL-based business queries, and an interactive Power BI dashboard.

## Objective

To identify which factors — subscription level, IPO type, sector, issue size — are associated with strong listing-day performance, and whether listing gains hold up over the following month.

## Dataset

- **Source file:** `IPO_Listing_Performance_5yr.xlsx`
- **Size:** 4,256 IPOs, 21 raw columns (expanded to 39 after cleaning and feature engineering)
- **Period:** September 2020 - September 2025 (2020 and 2025 are partial years)
- **Fields:** company details, sector, exchange, issue price, issue size, subscription levels (QIB/Retail), listing-day prices, 1-month post-listing price

## Tools and Technologies

| Tool | Purpose |
|---|---|
| Python (Pandas, NumPy) | Data cleaning, feature engineering, EDA |
| Matplotlib, Seaborn | All charts and visualizations |
| SciPy | Statistical significance tests (Mann-Whitney, Kruskal-Wallis) |
| scikit-learn | Logistic Regression and Random Forest prediction model |
| MySQL | Relational database, business-question queries |
| mysql-connector-python | Connects the project to MySQL and retrieves data into the notebook |
| Power BI | Interactive dashboard with DAX measures |

## Repository Structure


## How to Run

### 1. Python analysis
```bash
pip install pandas numpy matplotlib seaborn scipy scikit-learn openpyxl mysql-connector-python
python ipo_analysis.py
```
Or open `ipo_analysis.ipynb` in Jupyter and run all cells. Keep `IPO_Listing_Performance_5yr.xlsx` in the same folder.

### 2. MySQL
1. Open MySQL Workbench and run `ipo_mysql_setup.sql` to create the database and load the data (4,256 rows).
2. Run the queries in `ipo_queries_mysql.sql` one at a time to reproduce the business-question results.
3. Update the credentials in `db_connector.py`, then run it to pull the data into Python directly from MySQL:
```python
   from db_connector import fetch_ipo_data
   df = fetch_ipo_data()
```

### 3. Power BI
Open `IPO_Dashboard.pbix` in Power BI Desktop. It connects to the cleaned dataset and lets you filter by year, sector, and IPO type.

## Data Cleaning

The raw file had six data-quality issues, all logged and fixed in `ipo_analysis.py`:
- Inconsistent sector spelling (15 rows)
- IPO type contradicting the exchange field (4 rows)
- Negative issue sizes, treated as sign errors (4 rows)
- Issue price about 10x too high (6 rows), back-solved from the listing price and reported gain
- Missing listing gain (17 rows), recomputed from prices
- Genuinely missing subscription/issue-size data (17 rows), left blank rather than guessed

## Key Insights

- Across all IPOs, the **average listing gain was 12.7%**, and **69.6% listed at a gain**.
- **Subscription level is the strongest signal:** IPOs subscribed 30x+ averaged **29.8%** gain vs **0.6%** for those under 1x. Even so, **17% of IPOs subscribed 10x+ still listed at a loss**.
- **SME IPOs averaged 17.0%** gain vs **7.3% for Mainboard**, but require roughly 12x more capital per lot (~Rs 1.94 lakh vs ~Rs 16,000).
- **Sector is not a reliable driver** — differences across sectors are not statistically significant (p = 0.90), and the best-performing sector changes almost every year.
- **Gains fade after listing:** the biggest listing-day gainers ("Bumper Listing") averaged ~61% on day one but only ~33% a month later.
- A prediction model using only pre-listing data reached **ROC-AUC 0.66** — a real but weak edge, not a reliable forecast.

Full detail, charts, and statistical tests are in `IPO_Analysis_Report.pdf`.

## Conclusion

Subscription level and IPO type are the two most dependable factors behind IPO listing performance, while sector-based patterns are largely noise. Listing-day price momentum is not fully sustained a month later, so treating a strong listing as a guaranteed long-term winner is not supported by the data.

## Recommendations

- Use subscription level as a first-pass filter, not a guarantee of gains.
- Treat SME IPOs as a higher-risk, higher-reward category given the larger capital requirement.
- Avoid sector-rotation strategies specifically for IPOs.
- Consider booking listing-day gains rather than assuming they will hold, especially for heavily oversubscribed "Bumper Listing" IPOs.

## Author

**Ishwari Gurde**

