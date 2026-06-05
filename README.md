# copper-price-forecast

R-based project forecasting front-month copper futures prices (HG=F, USD cents/lb) using dynamic regression with ARIMA errors.

## Data Sources

| Variable | Source |
|---|---|
| Copper futures, DXY, Shanghai Composite | Yahoo Finance |
| Brent crude oil | FRED |
| CFTC non-commercial net position | CFTC (manual download) |

## Pipeline

SQL Server Express (`CopperForecast` database), medallion architecture:

- **Bronze** — raw CSV data ingested from R
- **Silver** — cleaned, forward-filled, filtered to Friday closes (`silver.load_silver`)
- **Gold** — joined view across all five series (`gold.master_table`)

## Reproduce

1. Run `R/01_fetch.R` — fetches market data from Yahoo Finance and FRED
2. Run `R/02_load.R` — loads CSVs and COT zip files into bronze layer
3. Execute `EXEC silver.load_silver` in SQL Server — populates silver layer
4. Query `gold.master_table` — analytic-ready dataset

## Dependencies

- R packages: `fredr`, `tidyquant`, `tidyverse`, `readxl`, `DBI`, `odbc`
- SQL Server Express (local)
- CFTC COT zip files (manual download, place in `data/raw/cot/`)
