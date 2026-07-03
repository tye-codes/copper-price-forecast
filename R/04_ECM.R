library(DBI) # Database interface package - standard for connect R to RDBMS
library(odbc) # has a DBI compliant interface to connect to SQL Server
library(dplyr)
library(strucchange) #https://cran.r-project.org/web/packages/strucchange/strucchange.pdf
library(tseries)
library(broom)
library(ggplot2)
library(MASS)
library(forecast)

set.seed(42)

#-------------------------
#Load Data
#-------------------------
con <- dbConnect(
  drv = odbc::odbc(),
  Driver = "ODBC Driver 17 for SQL Server",
  Server = "localhost\\SQLEXPRESS",
  Database = "CopperForecast",
  Trusted_Connection = "Yes")

master_table <- dbGetQuery(con, "SELECT * FROM gold.master_table") %>% 
  mutate(date = as.Date(date),
         brent_price = log(brent_price),
         shanghai_close = log(shanghai_close))

#--------------------------------
#test-train set 80-20
#---------------------------------


cutoff_row <- round(0.80 * nrow(master_table))

train_set <- master_table %>% filter(row_number() <= cutoff_row)
test_set <- master_table %>% filter(row_number() > cutoff_row)


#----------------------------------
#Box-Cox Transform
#----------------------------------

bc <- boxcox(lm(train_set$dxy ~ 1), lambda = seq(-2,2,0.01))

lambda_hat <- bc$x[which.max(bc$y)]

ci_lambdas <- bc$x[bc$y > max(bc$y) - 0.5 * qchisq(0.95, df = 1)]
ci_lower <- min(ci_lambdas)
ci_upper <- max(ci_lambdas)



boxcox_results <- data.frame(
  statistic =c("ci_lower","point_estimate","ci_upper"),
  lambda=c(ci_lower, lambda_hat, ci_upper)
)

train_set <- mutate(train_set, copper_price = log(copper_price))

write.csv(boxcox_results, "outputs/02-ecm-train/boxcox_lambda.csv", row.names = FALSE)

copper_ts <- ggplot(train_set, 
                    aes(x = date, y = copper_price)) +
  geom_line() +
  labs(x = "date", y = "log(copper_price)", title = "Log of Copper Price")

ggsave("outputs/02-ecm-train/bc-copper-ts.png", plot = copper_ts, width = 10, height =5)

#With 0 in the confidence interval we cannot reject a log transform at
#the 5% level. Converting to lambda = 0 allows us to interpret changes 
#as a percentage change. 

#----------------------------------------------------
#Testing the data for structural changes on the mean
#----------------------------------------------------

#if the data has a unit-root it is non-stationary. When testing H0 for breakpoints on non-stationary data, the null
#will be over rejected. H0 for the breakpoint hypothesis is, no break present parameters are constant across sample.
#the hypothesis tests also assume stationality in the data being tested. ie, there is a fixed mean the data continues 
#return to. If the series is not stationary, this implicitly defines there is no fixed mean. So we test on a differenced
#stationary series to find the breakpoints. 

tests <- list(
  tseries::adf.test(train_set$copper_price),                 # H0: unit root. Expect: fail to reject (p large)
  tseries::adf.test(diff(train_set$copper_price)),           # Expect: reject (p small) -> increments stationary
  tseries::kpss.test(train_set$copper_price),                # H0: stationary. Expect: reject -> not stationary
  tseries::kpss.test(diff(train_set$copper_price))           # H0: stationary. Expect: reject -> not stationary
)


results_copper <- bind_rows(lapply(tests, tidy), .id = "test")
write.csv(results, "outputs/02-ecm-train/stationarity_tests.csv", row.names = FALSE)

tests <- list(
  tseries::adf.test(train_set$copper_price),                 
  tseries::adf.test(diff(train_set$copper_price)),           
  tseries::kpss.test(train_set$copper_price),                
  tseries::kpss.test(diff(train_set$copper_price))           
)

#--------------------------------------------------------------------
# Johansen test for cointegration
#--------------------------------------------------------------------
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





