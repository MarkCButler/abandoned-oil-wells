library(ggplot2)
library(scales)
library(tidyr)

# Functions in this file generate plots that show how the status of abandoned
# wells in Texas has varied over time.

source('filenames.R')

unplugged_wells <- read.csv(unplugged_wells_path)
plugging_history <- read.csv(plugging_history_path)

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
