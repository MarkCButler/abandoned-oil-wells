library(plotly)
library(shiny)

source('time_plots.R')
source('status_plots.R')

server <- function(input, output) {

    output$recently_abandoned <- renderPlot({
        plot_distribution_history(
            column_name = 'Recently_abandoned',
            title = paste0('Wells inactive < 1 year\n',
                           'with delinquent paperwork')
        )
    })

    output$active_wells <- renderPlot({
        plot_distribution_history(
            column_name = 'Active',
            title = 'Active wells'
        )
    })

    output$recently_inactive <- renderPlot({
        plot_distribution_history(
            column_name = 'Recently_inactive',
            title = 'All wells inactive < 1 year'
        )
    })

    output$stock_price <- renderPlot({
        plot_price_history()
    })

    output$plugging_history <- renderPlot({
        plot_plugging_history()
    })

    output$risk_level <- renderPlot({
        plot_risk_level()
    })
    output$district_totals_map <- renderPlotly({
        generate_map(data = region_totals, data_label = 'Districts')
    })

    output$county_totals_map <- renderPlotly({
        generate_map(data = region_totals, data_label = 'Counties')
    })

    output$county_totals_hist <- renderPlot({
        plot_county_totals()
    })

    output$county_totals_old_wells <- renderPlotly({
        generate_map(data = region_totals_old_wells,
                     data_label = 'Counties')
    })

    output$inactive_period_texas <- renderPlot({
        plot_inactive_period()
    })

    output$inactive_period_pecos <- renderPlot({
        plot_inactive_period(county_name = 'Pecos')
    })

    output$inactive_period_hutchinson <- renderPlot({
        plot_inactive_period(county_name = 'Hutchinson')
    })
}
