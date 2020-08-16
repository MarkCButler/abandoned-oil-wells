library(dplyr)
library(ggplot2)
library(plotly)
library(rjson)

# Functions in this file generate maps and plots analyzing the current status
# of abandoned wells in Texas.

source('filenames.R')

# Several variables used in generating plots are defined outside of functions.
# These variables, which only need to be defined once, can be reused in
# function calls that generate distinct plots or maps.

# Table giving the current information about abandoned wells.
abandoned_wells <- read.csv(abandoned_wells_path, check.names = F,
                            stringsAsFactors = F)

# Table giving the district name and FIPS codes for each county.
counties_csv <- read.csv(counties_csv_path,
                         check.names = F,
                         colClasses = c(FIPS = 'character'),
                         stringsAsFactors = F)

# GeoJSON data used by plotly to generate a choropleth map based on FIPS codes.
counties_json <- fromJSON(file = counties_json_path)

# Create a data frame that gives the total number of abandoned wells per
# county and RRC district, along with FIPS codes that can be used for plotly
# maps.  Filter out the wells that have not been abandoned at least N months,
# where N is given by argument months_inactive.  The default value of
# months_inactive is NULL, which disables the filtering.
#
# For an interactive app, there would be a widget allowing the user to choose
# different values of months_inactive to see the data, but current app only
# presents data.
get_region_totals <- function(data = abandoned_wells, months_inactive = NULL) {

    if (!is.null(months_inactive)) {
        data <- filter(data, MONTHS_INACTIVE >= months_inactive)
    }

    # Find the number of missing wells per county.  In order to avoid holes in the
    # choropleth map, set the county total to zero for each county not already in
    # the table.  This is done by performing a full join and then setting NA to in
    # the COUNTY_TOTAL column to zero.
    county_totals <- select(data, COUNTY_NAME) %>%
        group_by(COUNTY_NAME) %>%
        summarise(COUNTY_TOTAL = n()) %>%
        ungroup() %>%
        full_join(counties_csv, by = 'COUNTY_NAME')
    bool_index <- is.na(county_totals[['COUNTY_TOTAL']])
    county_totals[bool_index, 'COUNTY_TOTAL'] <- 0

    # The data includes information about offshore wells that have been abandoned.
    # Offshore counties were not included in the downloaded geojson data.  As a
    # result, there is some missing data in the FIPS columns of the dataframe.
    # For the map these rows are dropped.
    county_totals <- na.omit(county_totals)

    # Finte the number of missing wells per district.  Note that offshore abandoned
    # wells are included in the district totals.  So on the map the sum of the
    # district totals will be larger than the sum of the county totals.
    district_totals <- select(data, DISTRICT_NAME) %>%
        group_by(DISTRICT_NAME) %>%
        summarise(DISTRICT_TOTAL = n()) %>%
        ungroup()

    # Join county and district totals.  This
    region_totals <- inner_join(county_totals, district_totals, by = 'DISTRICT_NAME')

    return(region_totals)
}

region_totals <- get_region_totals()

region_totals_old_wells <- get_region_totals(months_inactive = 240)

# Helper function for plotting maps.
setup_map_plot <- function(data_label, months_inactive) {

    if (is.null(months_inactive)) {
        title_detail <- ''
    } else {
        years <- months_inactive %/% 12
        months <- months_inactive %% 12
        if (months == 0) {
            title_detail <- sprintf('\ninactive at least %d years', years)
        } else {
            title_detail <- sprintf('\ninactive at least %d years, %d months', years, months)
        }
    }

    if (data_label == 'Counties') {
        plot_info <- c(
            count = 'COUNTY_TOTAL',
            name = 'COUNTY_NAME',
            hovertemplate = '%{text} County<br>Total: %{z:,d}<extra></extra>',
            title = paste0('Number of abandonded wells per county', title_detail)
        )
    } else {
        plot_info <- c(
            count = 'DISTRICT_TOTAL',
            name = 'DISTRICT_NAME',
            hist_title = '',
            hovertemplate = 'District %{text}<br>Total: %{z:,d}<extra></extra>',
            title = paste0('Number of abandonded wells per district', title_detail)
        )
    }

    return(plot_info)
}

generate_map <- function(data_label, data, months_inactive = NULL) {

    plot_info <- setup_map_plot(data_label, months_inactive)

    # It seems that for choropleth maps, plotly requires the column names used
    # for the plot to be indicated as formulas, e.g., ~WELL_COUNT.  Inside the
    # current function, however, column names are stored in variables, e.g.,
    # plot_info['count'].
    #
    # The command below renames columns so that they can be referred to in
    # formulas.  Since the choice of column names to be renamed is stored in
    # variables, we need to index into the .data pronoun.  For instance, the
    # argument
    #
    # WELL_COUNT = .data[[plot_info['count']]]
    #
    # indicates that the string stored in plot_info['count'] gives the column
    # name that should be changed to 'WELL_COUNT'.
    data <- rename(data,
                   WELL_COUNT = .data[[plot_info['count']]],
                   NAME = .data[[plot_info['name']]])

    geo <- list(fitbounds = "locations",
                visible = F)

    hover_annotation <- list(x = 0.5, y = -0.1,
                             text = 'Hover over states to see details',
                             showarrow = F,
                             font = list(size = 16))

    colorbar_title <- 'Number of\nabandoned wells'

    fig <- plot_geo(data,
                    color = ~WELL_COUNT,
                    locationmode = 'geojson-id') %>%
        add_trace(type = 'choropleth',
                  geojson = counties_json,
                  locations = ~FIPS,
                  z = ~WELL_COUNT,
                  text = ~NAME,
                  reversescale = F,
                  colorscale = 'RdBu',
                  hovertemplate = plot_info['hovertemplate']) %>%
        colorbar(title = colorbar_title) %>%
        layout(geo = geo,
               title = plot_info['title'],
               annotations = hover_annotation) %>%
        config(displayModeBar = F, scrollZoom = F)

    return(fig)
}


plot_county_totals <- function() {

    county_totals <- select(abandoned_wells, COUNTY_NAME) %>%
        group_by(COUNTY_NAME) %>%
        summarise(COUNTY_TOTAL = n()) %>%
        ungroup()

    fig <- ggplot(county_totals, aes(x = COUNTY_TOTAL)) +
        geom_histogram(fill = 'navyblue', bins = 30) +
        scale_x_continuous(name = 'Number of abandoned wells') +
        scale_y_continuous(name = 'Number of counties') +
        ggtitle('Number of abandonded wells per county') +
        theme_grey(base_size = 18)

    return(fig)
}

plot_district_totals <- function() {

    district_totals <- select(abandoned_wells, DISTRICT_NAME) %>%
        group_by(DISTRICT_NAME) %>%
        summarise(DISTRICT_TOTAL = n()) %>%
        ungroup()

    fig <- ggplot(district_totals,
                  aes(x = DISTRICT_NAME, y = DISTRICT_TOTAL)) +
        geom_bar(stat = 'identity',
                 fill = 'navyblue') +
        scale_x_discrete(name = 'District') +
        scale_y_continuous(name = 'Number of abandoned wells') +
        ggtitle('Number of abandonded wells per district') +
        theme_grey(base_size = 18)

    return(fig)
}

plot_inactive_period <- function(county_name = NULL) {

    title <- 'Distribution of abandoned-well lifetime '

    if (is.null(county_name)) {
        data <- select(abandoned_wells, MONTHS_INACTIVE)
        title <- paste0(title, ' in all Texas counties')
    } else {
        data <- filter(abandoned_wells, COUNTY_NAME == county_name) %>%
            select(MONTHS_INACTIVE)
        title <- paste0(title, ' in ', county_name, ' County')
    }

    fig <- ggplot(data, aes(x = MONTHS_INACTIVE)) +
        geom_histogram(fill = 'navyblue', bins = 30) +
        scale_x_continuous(name = 'Number of months inactive') +
        scale_y_continuous(name = 'Number of abandoned wells') +
        ggtitle(title) +
        theme_grey(base_size = 18)

    return(fig)
}
