library(DBI) # Database interface package - standard for connect R to RDBMS
library(odbc) # has a DBI compliant interface to connect to SQL Server
library(GGally)
library(ggplot2)
library(dplyr)
library(tseries)
library(strucchange)

con <- dbConnect(
  drv = odbc::odbc(),
  Driver = "ODBC Driver 17 for SQL Server",
  Server = "localhost\\SQLEXPRESS",
  Database = "CopperForecast",
  Trusted_Connection = "Yes")


master_table <- dbGetQuery(con, "SELECT * FROM gold.master_table")

# time series plot
time_series <- ggplot(master_table, aes(x = date, y = copper_price)) +
  geom_line() +
  labs(title = "Copper Price Series", y = "Copper Price")

#Correlation matrix of all regressors and copper price
correl_matrix <- ggpairs(
  master_table,
  columns = names(dplyr::select(master_table,-date)),
  lower = list(continuous = wrap("points", size = 0.3, alpha = 0.5, lwd = 0.5))
)

#dxy is showing multimodal peaks - colour scatter plots to find if true
vars <- c("copper_price", "brent_price", "net_position", "dxy", "shanghai_close")

plots <- lapply(vars, function(v) {
  ggplot(master_table %>%
           mutate(period = case_when(
             date < as.Date("2014-01-01") ~ "pre_2014",
             date >= as.Date("2014-01-02") & date < as.Date("2021-01-01") ~ "2015_2021",
             date >= as.Date("2021-01-02") ~ "post_2021"
           )),
         aes(x = dxy, y = .data[[v]], colour = period)) +
    geom_point(size = 0.5, alpha = 0.5) +
    theme_minimal()
})

# arrange all plots in a grid
dxy_scatter <- patchwork::wrap_plots(plots)

#structural break inferred through dxy relationship

bp <- breakpoints(copper_price ~ brent_price + net_position + dxy + shanghai_close,
            h = 0.15,
            data = master_table)

plot(bp)
summary(bp)


# saving files for claude to use in the report.
ggsave("outputs/figures/dxy_scatter.png", plot = dxy_scatter, width = 10, height = 5)
ggsave("outputs/figures/ggpairs_correlation.png", plot = correl_matrix, width = 10, height = 8)
ggsave("outputs/figures/time_series.png", plot = time_series, width = 10, height = 8)

