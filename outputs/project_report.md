# Copper Futures Price Forecasting — Project Report

## Abstract

This project develops a medium-term forecasting model for copper futures prices (HG=F, USD cents/lb) using dynamic regression with ARIMA errors. Five macroeconomic and positioning variables sourced from Yahoo Finance, FRED, and the CFTC are processed through a SQL Server medallion ETL pipeline before being used to forecast weekly copper price movements.

---

## Introduction

Copper is a widely-used leading indicator of global economic activity, with prices sensitive to industrial demand, currency movements, and speculative positioning. This project forecasts the front-month copper futures price (HG=F) over a medium-term horizon using publicly available macroeconomic signals.

**Research question:** Can macroeconomic and positioning indicators — the US Dollar Index, Brent crude oil, Chinese equity markets, and CFTC non-commercial net positioning — improve copper price forecasts beyond a univariate baseline?

---

## Method

### Variable Selection

| Variable | Source | Identifier |
|---|---|---|
| Copper futures price | Yahoo Finance | HG=F |
| US Dollar Index (DXY) | Yahoo Finance | DX-Y.NYB |
| Brent crude oil | FRED | DCOILBRENTEU |
| Shanghai Composite | Yahoo Finance | 000001.SS |
| CFTC COT Managed Money net position | CFTC (manual) | Disaggregated futures |

Variables considered and rejected: Chinese PMI (no free API with sufficient history), COMEX inventory (not on FRED), US copper stocks (historical archive only), Strait of Hormuz/sulfur shipping risk.

### Data Pipeline

A medallion architecture (bronze → silver → gold) was implemented in SQL Server Express (`CopperForecast` database).

**Bronze** — Raw CSVs ingested from R (`01_fetch.R`, `02_load.R`). No transformations applied; data stored as-is for auditability.

**Silver** — Cleaned and standardised via stored procedure (`silver.load_silver`). Key transformations: dates cast from VARCHAR to DATE, forward-fill applied to handle non-trading days and data gaps, all series filtered to Friday weekly closes for consistent model alignment across series.

**Gold** — A view (`gold.master_table`) joins all five silver tables on date via INNER JOINs, producing a single analytic-ready dataset. A view was chosen over a physical table because the dataset is small (~1,000 rows), and the view always reflects the current silver state without requiring a separate load step.

Weekly refresh cadence: Saturdays, after all Friday US market closes and CFTC COT release (Fridays 3:30pm ET) are available. All five series were validated — no NULLs returned from `gold.master_table`.

### Model

Dynamic regression with ARIMA errors, implemented in R. This approach was chosen over a plain GLM to account for autocorrelated residuals inherent in weekly time series data. Train/test split: TBD.

---

## Results

*To be completed.*

---

## Conclusion

*To be completed.*
