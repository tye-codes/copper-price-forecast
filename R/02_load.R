library(DBI) # Database interface package - standard for connect R to RDBMS
library(odbc) # has a DBI compliant interface to connect to SQL Server

start_time = Sys.time()

#=================================================
# 1. Open connection to DB and store as con.

# Notes: 
# Driver is previously installed, Data base and schemas
# already initiated. drv will use odbc for connection and 
# language

con <- dbConnect(
          drv = odbc::odbc(),
          Driver = "ODBC Driver 17 for SQL Server",
          Server = "localhost\\SQLEXPRESS",
          Database = "CopperForecast",
          Trusted_Connection = "Yes")


# 2. Write tables to SQL
# a) # read the unzipped csv files to a df in RStudio
#--------------------------------------------------- 
copper_price <- read.csv("data/raw/copper_price.csv")
brent <- read.csv("data/raw/brent.csv")
dxy <- read.csv("data/raw/dxy.csv")
shanghai_composite <- read.csv("data/raw/shanghai_composite.csv")
#---------------------------------------------------

# b) Write the df to a table in the bronze schema.
#-------------------------------------------------- 
# Notes: 
# overwrite = TRUE because data will constantly change new data


dbWriteTable(conn = con,
             name = DBI::Id(schema = "bronze",
                    table = "copper_price"),
             value = copper_price,
             overwrite = TRUE)

dbWriteTable(conn = con,
             name = DBI::Id(schema = "bronze",
                            table = "brent"),
             value = brent,
             overwrite = TRUE)

dbWriteTable(conn = con,
             name = DBI::Id(schema = "bronze",
                            table = "dxy"),
             value = dxy,
             overwrite = TRUE)

dbWriteTable(conn = con,
             name = DBI::Id(schema = "bronze",
                            table = "shanghai_composite"),
             value = shanghai_composite,
             overwrite = TRUE)
#-------------------------------------------------- 

# c) unzip the zipped files using a loop.
# files are then appended to a single table
# and then written to sql server.
#-----
zip_files <- list.files(path = "data/raw/cot",
           pattern = "\\.zip$",
           full.names = TRUE)

results <- list()

for (i in 1:length(zip_files)) {
  unzip(zipfile = zip_files[i],
        exdir = file.path(tempdir(), paste0("cot_", i))
      )
  
  xls_file <- list.files(
    path = file.path(tempdir(), 
              paste0("cot_",i)), 
    pattern = "\\.xls$",
    full.names = TRUE)
  for (xls in xls_file) {
    df <- readxl::read_excel(xls) 
      
    df <- df[grepl("COPPER.*#1.*COMMODITY EXCHANGE INC", 
                   df$Market_and_Exchange_Names),]
    
    df <- df[, c("Report_Date_as_MM_DD_YYYY",
               "M_Money_Positions_Long_ALL",
               "M_Money_Positions_Short_ALL"
               )]
    results[[length(results) + 1]] <- df
  }
}

cot_copper <- do.call(rbind, results)
cot_copper$net_position <-cot_copper$M_Money_Positions_Long_ALL - cot_copper$M_Money_Positions_Short_ALL

dbWriteTable(conn = con,
             name = DBI::Id(schema = "bronze",
                            table = "cot_copper"),
             value = cot_copper,
             overwrite = TRUE)
#----

dbDisconnect(con)

run_time <- as.numeric(Sys.time() - start_time, units = "secs")
print(paste0("Total Run Time: ", round(run_time, 2), " seconds"))
