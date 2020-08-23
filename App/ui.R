library(plotly)
library(shiny)
library(shinythemes)

# This CSS string will be placed in the header, overriding the CSS of the
# theme loaded from an external file.
css_string <- HTML('
img {
  width: 100%;
  height: auto;
}

a {
    color: #99ccff;
}

h1 {
    font-size: 400%;
    text-align: center;
}

h2 {
    font-size: 300%;
}

h3 {
    font-size: 250%;
}

p {
    font-size: 200%;
}

ul {
    font-size: 150%;
}

.footnote {
    font-size: 100%;
}

.sources {
    font-size: 110%;
}

.aux-header {
    font-size: 150%
}
')

# Define some string variables to make the code for the user interface more
# readable.
page_title <- 'Abandoned Oil and Gas Wells in Texas'

reuters_footnote <- paste0(
    '[1] Nichola Groom, "Special Report: Millions of abandoned oil wells are ',
    'leaking methane, a climate menace", www.reuters.com, June 16, 2020'
)

data_source_wells <- 'https://www.rrc.state.tx.us/'
data_source_stocks <- 'https://finance.yahoo.com/'
source_code <- 'https://github.com/MarkCButler/abandoned-wells-app'


ui <- fluidPage(
    title = page_title,
    theme = shinytheme('slate'),
    tags$head(
        tags$style(css_string)
    ),
    fluidRow(
        column(
            width = 10,
            offset = 1,
            h1(page_title)
        )
    ),
    fluidRow(
        column(
            width = 6,
            offset = 1,
            img(src = 'texas_oil_wells.jpg')
        ),
        column(
            width = 4,
            p('Place holder'),
            tags$ul(
                tags$li(
                    'Some information ',
                    'with a footnote [1].'
                ),
                tags$li(
                    'Some more ',
                    'information.'
                )
            )
        )
    ),
    br(),
    fluidRow(
        column(
            offset = 1,
            width = 4,
            p('Place holder'),
        ),
        column(
            width = 6,
            img(src = 'flowing_water.jpg')
        )
    ),
    br(),
    fluidRow(
        column(
            width = 10,
            offset = 1,
            h2('Place-holder header'),
        )
    ),
    fluidRow(
        column(
            width = 5,
            offset = 1,
            plotOutput('recently_abandoned')
        ),
        column(
            width = 5,
            plotOutput('active_wells')
        )
    ),
    br(),
    fluidRow(
        column(
            width = 10,
            offset = 1,
            p('Some text')
        )
    ),
    br(),
    fluidRow(
        column(
            width = 5,
            offset = 1,
            plotOutput('recently_inactive')
        ),
        column(
            width = 5,
            plotOutput('stock_price')
        )
    ),
    br(),
    fluidRow(
        column(
            width = 10,
            offset = 1,
            h2('Are the wells getting plugged?'),
        )
    ),
    fluidRow(
        column(
            width = 4,
            offset = 1,
            p('Place holder')
        ),
        column(
            width = 6,
            plotOutput('plugging_history'),
        )
    ),
    br(),
    fluidRow(
        column(
            width = 10,
            offset = 1,
            h2('Abandoned wells by district'),
        )
    ),
    fluidRow(
        column(
            width = 8,
            offset = 2,
            plotlyOutput('district_totals_map')
        )
    ),
    br(),
    fluidRow(
        column(
            width = 6,
            offset = 1,
            plotOutput('district_totals_hist'),
        ),
        column(
            width = 4,
            p('Some discussion')
        )
    ),
    br(),
    fluidRow(
        column(
            width = 10,
            offset = 1,
            h2('Abandoned wells by county'),
        )
    ),
    fluidRow(
        column(
            width = 8,
            offset = 2,
            plotlyOutput('county_totals_map')
        )
    ),
    br(),
    fluidRow(
        column(
            width = 4,
            offset = 1,
            p('Some discussion')
        ),
        column(
            width = 6,
            plotOutput('county_totals_hist'),
        )
    ),
    br(),
    fluidRow(
        column(
            width = 10,
            offset = 1,
            h2('How long have wells been abandoned?'),
        )
    ),
    fluidRow(
        column(
            width = 6,
            offset = 1,
            plotOutput('inactive_period_texas'),
        ),
        column(
            width = 4,
            p('Some discussion')
        )
    ),
    br(),
    fluidRow(
        column(
            width = 10,
            offset = 1,
            h2('Abandoned wells inactive at least 20 years'),
        )
    ),
    fluidRow(
        column(
            width = 8,
            offset = 2,
            plotlyOutput('county_totals_old_wells')
        )
    ),
    br(),
    fluidRow(
        column(
            offset = 1,
            width = 4,
            p('Pecos County'),
        ),
        column(
            width = 6,
            plotOutput('inactive_period_pecos'),
        )
    ),
    br(),
    fluidRow(
        column(
            width = 6,
            offset = 1,
            plotOutput('inactive_period_hutchinson'),
        ),
        column(
            width = 4,
            p('Hutchinson County'),
        )
    ),
    br(),
    fluidRow(
        column(
            width = 12,
            h4(
                class = 'aux-header',
                'References'
            ),
            p(
                class = 'footnote',
                reuters_footnote
            )
        )
    ),
    fluidRow(
        column(
            width = 12,
            h4(
                class = 'aux-header',
                'Data sources'
            ),
            p(
                class = 'sources',
                'Oil and gas wells: ',
                a(href = data_source_wells, data_source_wells)
            ),
            p(
                class = 'sources',
                'Stock prices:  ',
                a(href = data_source_stocks, data_source_stocks)
            ),
            h4(
                class = 'aux-header',
                'Source code'
            ),
            a(
                class = 'sources',
                href = source_code, source_code
            )
        )
    ),
    br()
)
