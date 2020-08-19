library(dplyr)
library(stringr)
library(rjson)

source('filenames.R')

# The code in this file was run only once.  It does some preprocessing of the
# data scraped from the web.


#######################################
# Preprocess data for status_plots.R
#######################################

abandoned_wells <- read.csv(abandoned_wells_path, check.names = F,
                            stringsAsFactors = F)

# Rename column WB_Months_Inactive for consistency with other column names.
abandoned_wells <- rename(abandoned_wells, MONTHS_INACTIVE = WB_Months_Inactive) %>%
    select(DISTRICT_NAME, COUNTY_NAME, MONTHS_INACTIVE)

# Format county names for display in the interactive plotly figure.
convert_county_names <- function(county_names) {
    county_names <- str_to_title(county_names)

    # The next four commands format capitalization for names such as
    # McMullen.
    bool_index <- (str_sub(county_names, 1, 2) == 'Mc')
    mc_names <- county_names[bool_index]
    str_sub(mc_names, 3, 3) <- toupper(str_sub(mc_names, 3, 3))
    county_names[bool_index] <- mc_names

    # DeWitt county is incorrectly labelled as De Witt in the csv file, which
    # leads to missing data in the map if the name is not corrected.
    bool_index <- (county_names == 'De Witt')
    county_names[bool_index] <- 'DeWitt'

    return(county_names)
}
abandoned_wells <- mutate(abandoned_wells,
                          COUNTY_NAME = convert_county_names(COUNTY_NAME))

# Get GeoJSON information on Texas counties for plotly.
#
# GeoJSON specifically for Texas counties is available from:
#
# url <- 'https://raw.githubusercontent.com/TNRIS/tx.geojson/master/counties/tx_counties.geojson'
#
# However, this data would require additional processing in order to be used
# with plotly, since it does not meet plotly's specification.
#
# A simpler approach is to download GeoJSON data on all US counties from plotly
# and then extract and save only the Texas counties
url <- 'https://raw.githubusercontent.com/plotly/datasets/master/geojson-counties-fips.json'
counties_json <- fromJSON(file = url)

filter_json <- function(json_data) {
    return(json_data$properties$STATE == '48')
}
bool_index <- sapply(counties_json$features, filter_json)
counties_json$features <- counties_json$features[bool_index]

# The data on abandoned wells obtained from The Texas Railroad Commission
# includes county names but not county FIPS codes.  Use the JSON to create a
# named vector that matches county names to FIPS codes.
get_FIPS_code <- function(json_data) {
    name <- json_data$properties$NAME
    code <- json_data$id[1]
    names(code)[1] <- name
    return(code)
}
FIPS_codes <- sapply(counties_json$features, get_FIPS_code)

# Read the table that tells which counties are included in each RRC district.
# (RRC is the acronym for the Texas Railroad Commission, which is
# responsible for regulating oil and gas wells in Texas.)
#
# Rename columns for consistency with other scraped data.
districts <- read.csv(districts_path, check.names = F, stringsAsFactors = F) %>%
    select(-CC) %>%
    rename(COUNTY_NAME = County,
           DISTRICT_NAME = DC)

# The name of Shackelford county is misspelled as 'Schackelford' in the table
# downloadded from RRC.  This needs to be corrected to avoid problems joining
# data frames.
bool_index <- districts[['COUNTY_NAME']] == 'Schackleford'
districts[bool_index, 'COUNTY_NAME'] <- 'Shackelford'

# Add FIPS codes and rename the resulting data frame.
counties_df <- mutate(districts,
                      FIPS = FIPS_codes[COUNTY_NAME])


#######################################
# Preprocess data for status_plots.R
#######################################

# Load the csv file giving the monthly distribution of unplugged wells since
# Jan 2014.
unplugged_wells <- read.csv(unplugged_wells_path, stringsAsFactors = F)

# The dates were scraped from a web page, and a couple of errors on that page
# need to be corrected.  Also, the date formate needs to be standardized.
bool_index <- (unplugged_wells[['Date']] == 'September_31_2019')
unplugged_wells[bool_index, 'Date'] <- 'September_30_2019'
bool_index <- (unplugged_wells[['Date']] == 'September_302014')
unplugged_wells[bool_index, 'Date'] <- 'September_30_2014'
unplugged_wells[['Date']] <- as.Date(unplugged_wells[['Date']], format = '%B_%d_%Y')

# The csv file giving the plugging history came from a scraped pdf file.
# The notation for fiscal years is inconsistent.  Replace this notation by
# integers.
plugging_history <- read.csv(plugging_history_path, stringsAsFactors = F)
plugging_history[['Fiscal_year']] <- str_extract(plugging_history[['Fiscal_year']], '\\d+')

# Load the csv file giving HAL stock prices since Jan 2014.  Discard the
# unneeded columns and unneeded digits in the stock price.
stock_prices <- read.csv(stock_prices_path, colClasses = c(Date = 'Date')) %>%
    select(Date, Adj.Close) %>%
    mutate(Price = round(Adj.Close, digits = 2)) %>%
    select(-Adj.Close)

# Save data.
writeLines(toJSON(counties_json), counties_json_path)
write.csv(abandoned_wells, abandoned_wells_path, row.names = F)
write.csv(counties_df, counties_csv_path, row.names = F)
write.csv(unplugged_wells, unplugged_wells_path, row.names = F)
write.csv(plugging_history, plugging_history_path, row.names = F)
write.csv(stock_prices, stock_prices_path, row.names = F)
