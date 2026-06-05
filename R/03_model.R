library(DBI) # Database interface package - standard for connect R to RDBMS
library(odbc) # has a DBI compliant interface to connect to SQL Server
library(fable)
library(tidyverse)
library(GGally)

con <- dbConnect(
  drv = odbc::odbc(),
  Driver = "ODBC Driver 17 for SQL Server",
  Server = "localhost\\SQLEXPRESS",
  Database = "CopperForecast",
  Trusted_Connection = "Yes")

master_table <- dbGetQuery(con, "SELECT * FROM gold.master_table")

time_series <- ggplot(data = master_table, 
       aes(date, copper_price)) +
  geom_line()

correl_matrix <- ggpairs(master_table %>% select(-date),
        lower = list(continuous = wrap("points", size = 0.5))) 

# saving files for claude to use in the report.
ggsave("outputs/figures/copper_price_ts.png", plot = time_series, width = 10, height = 5)
ggsave("outputs/figures/ggpairs_correlation.png", plot = correl_matrix, width = 10, height = 8)
