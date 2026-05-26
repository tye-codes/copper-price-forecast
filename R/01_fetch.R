#01_fetch.R
# Purpose: Fetch raw data from FRED and Yahoo Finance
# Output: CSV files saved to data/raw/

library(fredr) #Federal Reserve Economic Data
library(tidyquant) #Bridge between fredr and tidyverse
library(tidyverse)

#----
# API Setup

fredr_set_key(Sys.getenv("fred_api_key"))

#date range - 20 years prior %m-% handles leap years. 
start_date <- Sys.Date() %m-% years(20)
end_date <- Sys.Date()

#-----

# Creating csv files from available online data. 

#  1. Copper Futures Price - Yahoo Finance (HG=F, USD cents/lb, front month)
copper_raw <- tq_get("HG=F", from = start_date, to = end_date) %>%
  select(date, close) %>%
  rename(copper_price = close)

write_csv(copper_raw, "data/raw/copper_price.csv")
cat("Copper price:", nrow(copper_raw), "rows\n")

# 2. USD Index / DXY - Yahoo Finance
dxy_raw <- tq_get("DX-Y.NYB", from = start_date, to = end_date) %>% # uses the tidyquant package
  select(date, close) %>%
  rename(dxy = close)

write_csv(dxy_raw, "data/raw/dxy.csv")
cat("DXY:", nrow(dxy_raw), "rows\n")

# 3. Brent Crude Oil — FRED (DCOILBRENTEU, USD/barrel)
brent_raw <- fredr(series_id = "DCOILBRENTEU",
                   observation_start = start_date,
                   observation_end   = end_date) %>%
  select(date, value) %>%
  rename(brent = value)

write_csv(brent_raw, "data/raw/brent.csv")
cat("Brent crude:", nrow(brent_raw), "rows\n")

# 4. Shanghai Composite - Could not access Chinese manufacturing purchasing managers index.
shang_comp <- tq_get("000001.SS", from = start_date, to = end_date) %>%
  select(date, close) %>%
  rename(shanghai_close = close)

write_csv(shang_comp, "data/raw/shanghai_composite.csv")
cat("Shang Comp:", nrow(shang_comp), "rows\n")

# 5. CFTC COT Position has no API, weekly CSV download from:
# https://www.cftc.gov/MarketReports/CommitmentsofTraders/index.htm
# Handle in 02_load.R after manual download
cat("⚠ CFTC COT: manual download required — handle in 02_load.R\n")

cat("\nFetch complete. Files saved to data/raw/\n")



