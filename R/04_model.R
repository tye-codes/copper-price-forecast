library(DBI) # Database interface package - standard for connect R to RDBMS
library(odbc) # has a DBI compliant interface to connect to SQL Server
library(fable)
library(tidyverse)
library(feasts)
library(tsibble)
library(tseries)
#VARs
library(urca)
library(vars)
#markov switching 
library(MSwM)


con <- dbConnect(
  drv = odbc::odbc(),
  Driver = "ODBC Driver 17 for SQL Server",
  Server = "localhost\\SQLEXPRESS",
  Database = "CopperForecast",
  Trusted_Connection = "Yes")


master_table <- dbGetQuery(con, "SELECT * FROM gold.master_table")

n        <- nrow(master_table)
train_n  <- floor(0.8 * n)
train_data <- master_table[1:train_n, ]
test_data  <- master_table[(train_n + 1):n, ]


#box-cox transform for copper price
lambda <- train_data %>%
  as_tsibble(index = date) %>%
  features(copper_price, features = guerrero) %>%
  pull(lambda_guerrero)

train_data <- train_data %>%
  mutate(copper_price = box_cox(copper_price_adj, lambda))

#finding optimum lags for vector model
lag_select <- VARselect(
  train_data[,c("copper_price_adj", "brent_price", "net_position", "dxy", "shanghai_close")],
  lag.max = 10,
  type = "const"
)

lag_select$selection

# Johansen test for cointegration
# H0 - no cointegration amongst variables
# Cointegration Test using Trace Statistics 
# essentially tests if there is a common pattern between variables changing in time
# a question of relativity between the variables

m <- ca.jo(data.frame(train_data[,c("copper_price_adj", "brent_price", "net_position", "dxy", "shanghai_close")]),
        ecdet = "const", #constant term in cointegration
        type = "eigen", #eigenvectors are more reliable
        K=2
)

summary(m)

#VECM model

VCEM(data = )

MS_lm <- lm(copper_price_adj ~ ecm_term + dxy + brent_price + shanghai_close + net_position, 
        data = train_data)
msmFit(MS_lm, 
       k = 3, 
       sw = c(TRUE, FALSE, TRUE, FALSE, FALSE, FALSE, TRUE),
       p = 0
       )


