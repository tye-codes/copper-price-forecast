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

master_table <- dbGetQuery(con, "SELECT date, dxy FROM gold.master_table") %>% 
  mutate(date = as.Date(date)) 

ggplot(master_table, 
       aes(x = date, y = dxy)) +
  geom_line()


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

write.csv(boxcox_results, "outputs/01-ecm-train/boxcox_lambda.csv", row.names = FALSE)

#With 0 in the confidence interval we cannot reject a log transform at
#the 5% level. Converting to lambda = 0 allows us to interpret changes 
#as a percentage change. 
#


#-----------------------------------------------------
#Testing the data for structural changes on the mean


#if the data has a unit-root it is non-stationary. When testing H0 for breakpoints on non-stationary data, the null
#will be over rejected. H0 for the breakpoint hypothesis is, no break present parameters are constant across sample.
#the hypothesis tests also assume stationality in the data being tested. ie, there is a fixed mean the data continues 
#return to. If the series is not stationary, this implicitly defines there is no fixed mean. So we test on a differenced
#stationary series to find the breakpoints. 

tests <- list(
tseries::adf.test(master_table$dxy),                 # H0: unit root. Expect: fail to reject (p large)
tseries::adf.test(diff(master_table$dxy)),           # Expect: reject (p small) -> increments stationary
tseries::kpss.test(master_table$dxy),                # H0: stationary. Expect: reject -> not stationary
tseries::kpss.test(master_table$dxy, null = 'Trend')  # H0: stationary. Expect: reject -> not stationary
)

  results <- bind_rows(lapply(tests, tidy), .id = "test")
write.csv(results, "outputs/dxy_stationarity_tests.csv", row.names = FALSE)

#-----------------------------------------------------------

#-----------------------------------------------------------

d <- diff(master_table$dxy)

#this will see if the differenced copper level will return back towards a constant mean value. It is important to difference
#If differencing is not done, it will always suggest there is a structural break as a changing mean value is implicit
#with inflation and other ecomonic drivers consistently pushing prices of materials up over the long run.

bp <- breakpoints(d ~ 1, 
                  h = 0.15, #min interval size is 15% of sample size
                  data = master_table
)
plot(bp)
summary(bp)

#page 29 of the pdf
fs <- Fstats(d ~ 1, data = master_table, from = 0.15)
plot(fs, alpha = 0.01)
plot(fs, aveF = TRUE)
#H0 no structural break. p-value is 0.77 > 0.05 fail to reject NULL. Both breakpoints() and sctests() reject
#the presence of structural breaks
dxy_sctest_result <- sctest(fs, type = "supF")
write.csv(tidy(dxy_sctest_result),
          "outputs/dxy_sctest_result.csv",
          row.names = FALSE)


