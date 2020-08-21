library(plotly)
library(shiny)
library(shinydashboard)

############################
# Define header and sidebar
############################

header <- dashboardHeader(title = 'Abandoned Oil and Gas Wells in Texas',
                          titleWidth = 400)

sidebar <- dashboardSidebar(
    sidebarMenu(
        menuItem('Summary', tabName = 'summary', icon = icon('hand-point-right'), selected = T)
    )
)

###############################################################
# Define the layout of the five tabItems in the dashboard body
###############################################################

data_source_wells <- 'https://www.rrc.state.tx.us/'
data_source_stocks <- 'https://finance.yahoo.com/'
source_code <- 'https://github.com/MarkCButler/abandoned-wells-app'
summary_tab <- tabItem(
    tabName = 'summary',
    fluidRow(
        column(
            width = 10,
            plotlyOutput('county_totals_map')
        )
    ),
    fluidRow(
        column(
            width = 10,
            plotOutput('county_totals_hist'),
        )
    ),
    fluidRow(
        column(
            width = 10,
            plotlyOutput('district_totals_map')
        )
    ),
    fluidRow(
        column(
            width = 10,
            plotOutput('district_totals_hist'),
        )
    ),
    fluidRow(
        column(
            width = 10,
            plotlyOutput('county_totals_old_wells')
        )
    ),
    fluidRow(
        column(
            width = 10,
            plotOutput('inactive_period_texas'),
        )
    ),
    fluidRow(
        column(
            width = 10,
            plotOutput('inactive_period_pecos'),
        )
    ),
    fluidRow(
        column(
            width = 10,
            plotOutput('inactive_period_hutchinson'),
        )
    ),
    fluidRow(
        column(
            width = 10,
            plotOutput('plugging_history'),
        )
    ),
    fluidRow(
        column(
            width = 10,
            plotOutput('active_wells'),
        )
    ),
    fluidRow(
        column(
            width = 10,
            plotOutput('recently_inactive'),
        )
    ),
    fluidRow(
        column(
            width = 10,
            plotOutput('recently_abandoned'),
        )
    ),
    fluidRow(
        column(
            width = 10,
            plotOutput('stock_price'),
        )
    ),
    br(),
    fluidRow(
        column(
            width = 12,
            h4('Data sources'),
            p('Oil and gas wells: ',
              a(href = data_source_wells, data_source_wells)),
            p('Stock prices:  ',
              a(href = data_source_stocks, data_source_stocks)),
            h4('source_code'),
            a(href = source_code, source_code)
        )
    )
)

#####################################################
# Define the dashboard body and create the dashboard
#####################################################

body <- dashboardBody(
    tabItems(
        summary_tab
    )
)

dashboardPage(header, sidebar, body)
