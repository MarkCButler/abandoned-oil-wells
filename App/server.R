library(plotly)
library(shiny)

source('status_plots.R')
source('time_plots.R')

server <- function(input, output) {

    output$county_totals_map <- renderPlotly({
        generate_map(data = region_totals, data_label = 'Counties')
    })

    output$county_totals_hist <- renderPlot({
        plot_county_totals()
    })

    output$district_totals_map <- renderPlotly({
        generate_map(data = region_totals, data_label = 'Districts')
    })

    output$district_totals_hist <- renderPlot({
        plot_district_totals()
    })

    output$inactive_period_texas <- renderPlot({
        plot_inactive_period()
    })

    output$county_totals_old_wells <- renderPlotly({
        generate_map(data = region_totals_old_wells,
                     data_label = 'Counties',
                     months_inactive = 240)
    })

    output$inactive_period_pecos <- renderPlot({
        plot_inactive_period(county_name = 'Pecos')
    })

    output$inactive_period_hutchinson <- renderPlot({
        plot_inactive_period(county_name = 'Hutchinson')
    })

    output$plugging_history <- renderPlot({
        plot_plugging_history()
    })

    output$active_wells <- renderPlot({
        plot_distribution_history(column_name = 'Active', title = 'Active wells in Texas')
    })

    output$recently_inactive <- renderPlot({
        plot_distribution_history(column_name = 'Recently_inactive',
                                  title = 'Wells inactive < 1 year')
    })

    output$recently_abandoned <- renderPlot({
        plot_distribution_history(column_name = 'Recently_abandoned',
                                  title = 'Wells inactive < 1 year, delinquent on paperwork')
    })

    output$stock_price <- renderPlot({
        plot_price_history()
    })
}
