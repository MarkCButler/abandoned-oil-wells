library(dplyr)
library(ggplot2)
library(scales)
library(tidyr)

# Functions in this file generate plots that show how the variation over time
# of different categories of wells in Texas.

source('filenames.R')

plugging_history <- read.csv(plugging_history_path)
unplugged_wells <- read.csv(unplugged_wells_path, colClasses = c(Date = 'Date')) %>%
    select(Date, Active_wells, Inactive_under_1_yr, Inactive_under_1_yr_delinq_P5) %>%
    rename(Active = Active_wells,
           Recently_inactive = Inactive_under_1_yr,
           Recently_abandoned = Inactive_under_1_yr_delinq_P5)

stock_prices <- read.csv(stock_prices_path, colClasses = c(Date = 'Date'))

plot_plugging_history <- function() {
    # To simplify the plotting process with ggplot, gather the values of two
    # variables into a single column before plotting.
    data <- pivot_longer(plugging_history,
                         cols = c(Ending_population, Wells_plugged),
                         names_to = 'type',
                         values_to = 'Number_of_wells')
    data <- na.omit(data)

    fig <- ggplot(data,
                  aes(x = Fiscal_year, y = Number_of_wells, color = type)) +
        geom_line() +
        geom_point() +
        scale_color_discrete(name = '',
                             labels = c('Abandoned wells', 'Well plugged')) +
        scale_y_continuous(name = 'Number of wells',
                           labels = label_comma()) +
        scale_x_continuous(name = 'Year') +
        ggtitle('Progress in plugging abandoned wells') +
        theme_grey(base_size = 18)

    return(fig)
}

plot_distribution_history <- function(column_name, title) {

    fig <- ggplot(unplugged_wells,
                  aes_string(x = 'Date', y = column_name)) +
        geom_point(color = 'navyblue') +
        scale_y_continuous(name = 'Number of wells',
                           limits = c(0, NA),
                           labels = label_comma()) +
        ggtitle(title) +
        theme_grey(base_size = 18)

    return(fig)
}

plot_price_history <- function() {
    fig <- ggplot(stock_prices,
                  aes(x = Date, y = Price)) +
        geom_point(color = 'navyblue') +
        geom_line(color = 'navyblue') +
        scale_y_continuous(labels = dollar_format(),
                           limits = c(0, NA)) +
        ggtitle('Halliburton stock price') +
        theme_grey(base_size = 18)

    return(fig)
}
