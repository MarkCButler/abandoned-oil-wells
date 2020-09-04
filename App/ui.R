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
    text-align: center;
}

p {
    font-size: 200%;
}

li {
    font-size: 150%;
}

figcaption {
    font-size: 125%;
    margin-top: 15px;
}

.sub-bullet {
    font-size: 85%;
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

ny_times_footnote <- paste0(
    'Hiroko Tabuchi, "Fracking Firms Fail, Rewarding Executives and Raising ',
    'Climate Fears," The New York Times, July 12, 2020'
)
study_footnote <- paste0(
    'Ground Water Protection Council, "State Oil and Gas Agency Groundwater ',
    'Investigations," August 2011'
)
tribune_footnote <- paste0(
    'Jim Malewitz, "Abandoned Texas oil wells seen as \'ticking time bombs\' ',
    'of contamination," The Texas Tribune, Dec. 21, 2016'
)
mrt_footnote <- paste0(
    'Brandon Mulder, "Old oil wells pose problem for Pecos County," ',
    'Midland Reporter-Telegram, August 22, 2015'
)
reuters_footnote <- paste0(
    'Nichola Groom, "Special Report: Millions of abandoned oil wells are ',
    'leaking methane, a climate menace," Reuters, June 16, 2020'
)
handbook_footnote <- paste0(
    '"Handbook of Texas," Texas State Historical Association, ',
    'https://www.tshaonline.org/handbook'
)
de_footnote <- paste0(
    'DrillingEdge, http://www.drillingedge.com/texas/hutchinson-county'
)
museum_footnote <- paste0(
    'Hutchinson County Historical Museum, ',
    'https://www.hutchinsoncountymuseum.org/oil-boom.html'
)

data_source_wells <- 'https://www.rrc.state.tx.us/'
data_source_stocks <- 'https://finance.yahoo.com/'
source_code <- 'https://github.com/MarkCButler/abandoned-oil-wells-app'


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
            p('A disaster on the way?'),
            tags$ul(
                tags$li(
                    'The COVID-19 pandemic has led to a dramatic drop in the ',
                    'consumption of oil and gas.',
                ),
                tags$li(
                    'A sharp increase in the number of bankrupties in the ',
                    'oil and gas industry is expected [1].'
                ),
                tags$li(
                    'Will abandonment of wells by bankrupt operators ',
                    'do major harm to the environment?'
                ),
                tags$li(
                    'This project aims to shed light on that question by ',
                    'exploring the current situation in Texas.'
                )
            )
        )
    ),
    br(),
    fluidRow(
        column(
            offset = 1,
            width = 4,
            p('A threat to health and the environment'),
            tags$ul(
                tags$li(
                    'A study covering the period from 1993 to 2008 found 30 ',
                    'cases of groundwater contamination in Texas due to ',
                    'abandoned oil and gas wells [2].'
                ),
                tags$li(
                    'A 2016 news story reported that that since 2009, no new ',
                    'cases of groundwater contamination had been officially ',
                    'linked to abandoned wells [3].'
                ),
                tags$li(
                    'However, there are ongoing reports of polluted water from ',
                    'abandoned oil wells spilling out at the surface [3, 4].'
                ),
                tags$li(
                    'Wells not properly plugged can also leak methane, ',
                    'contributing to global warning.',
                    tags$ul(
                        tags$li(
                            class = 'sub-bullet',
                            'The US Environmental Protection Agency estimates that ',
                            'in 2018, such leakage was equivalent to burning 16 ',
                            'million barrels of crude, roughly one day\'s consumption ',
                            'for the full US [5].'
                        )
                    )
                )
            )
        ),
        column(
            width = 6,
            tags$figure(
                img(src = 'flowing_water.jpg'),
                tags$figcaption(
                    'Brackish water flowing from an abandoned well in Pecos ',
                    'County [3].'
                )
            )
        )
    ),
    br(),
    fluidRow(
        column(
            width = 6,
            offset = 3,
            h2('An increase in abandoned wells')
        )
    ),
    fluidRow(
        column(
            width = 6,
            offset = 3,
            plotOutput('recently_abandoned')
        )
    ),
    br(),
    fluidRow(
        column(
            width = 6,
            offset = 3,
            p(
                'The number of recently abandoned wells has jumped by roughly ',
                'a factor of 3 since late 2019.'
            ),
            tags$ul(
                tags$li(
                    'The final three points in the plot correspond to the months ',
                    'May to July in 2020.  This sharp increase was probably caused by ',
                    'the drop in demand due to the pandemic.'
                ),
                tags$li(
                    'The recent jump stands out more starkly because of the increases ',
                    'that occurred starting in late 2019. '
                )
            )
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
            plotOutput('active_wells')
        )
    ),
    br(),
    fluidRow(
        column(
            width = 10,
            offset = 1,
            p(
                'The jump in recently abandoned wells has been accompanied by a ',
                'steady increase in the number of recently inactive wells.'
            )
        )
    ),
    br(),
    fluidRow(
        column(
            width = 8,
            offset = 2,
            plotOutput('stock_price')
        )
    ),
    br(),
    fluidRow(
        column(
            width = 8,
            offset = 2,
            p(
                'The increase in the number of inactive wells is a symptom ',
                'of a struggling industry.'
            ),
            tags$ul(
                tags$li(
                    'Halliburton (HAL) has a major role in oilfield services in ',
                    'Texas.  The HAL stock price switched from its historical oscillating ',
                    'pattern to one of steady decline early in 2018, several months ',
                    'before the number of recently inactive wells began to rise.'
                ),
                tags$li(
                    'The same pattern can be seen more widely in stock prices in ',
                    'the oilfield services industry.  Service companies, which',
                    'earn revenue from exploration and from the development of ',
                    'new wells rather than from the sale of hydrocarbons, are ',
                    'among the first companies to lose revenue when there is a ',
                    'downturn in the oil and gas industry.'
                ),
                tags$li(
                    'A standard explanation of the struggles in the industry is that it is ',
                    'no longer viewed as a growth industry.  Because of the trend away ',
                    'from the use of hydrocarbons, investors are no longer expecting returns ',
                    'due to growth.  Instead they are looking at value metrics and ',
                    'current profitability.  In simple terms, investors are becoming much ',
                    'more demanding, and financing is difficult to obtain.  Many companies ',
                    'are struggling as a result.'
                )
            )
        )
    ),
    br(),
    fluidRow(
        column(
            width = 10,
            offset = 1,
            h2('Are the wells getting plugged?')
        )
    ),
    br(),
    fluidRow(
        column(
            width = 4,
            offset = 1,
            p('A persistent backlog'),
            tags$ul(
                tags$li(
                    'The Railroad Commission of Texas (RRC) is the agency responsible for ',
                    'regulating oil and gas wells in Texas.'
                ),
                tags$li(
                    'From 2004 to 2009, there was a steady decrease in the backlog of ',
                    'abandoned wells that the RRC is responsible for plugging.'
                ),
                tags$li(
                    'Since 2009, however, the backlog of wells needing to be plugged ',
                    'has not dropped below 5,000.'
                )
            )
        ),
        column(
            width = 6,
            tags$figure(
                plotOutput('plugging_history'),
                tags$figcaption(
                    'The upper trace shows the population of abandoned wells ',
                    'needing to be plugged, and the lower trace shows the number ',
                    'of wells plugged during the year.  The two points plotted ',
                    'for each year correspond to the end of the RRC fiscal year (Aug. 31).'
                )
            )
        )
    ),
    br(),
    fluidRow(
        column(
            width = 10,
            offset = 1,
            h2('Is the backlog of unplugged wells safe?')
        )
    ),
    br(),
    fluidRow(
        column(
            width = 8,
            offset = 2,
            plotOutput('risk_level')
        )
    ),
    br(),
    fluidRow(
        column(
            width = 8,
            offset = 2,
            p(
                'The backlog includes high-priority plugging jobs.'
            ),
            tags$ul(
                tags$li(
                    'The backlog of wells to be plugged consistently stays above 5,000.  ',
                    'Is this because there are ~5,000 abandoned wells that pose a very ',
                    'minor threat to health and to the environment?'
                ),
                tags$li(
                    'In the bar chart above, the risk level decreases from left ',
                    'to right, and \'TBD\' represents wells for which the risk level ',
                    'is being evaluated.'
                ),
                tags$li(
                    'The second-highest risk level, \'2H\',  includes ',
                    'over  1,000 abandoned wells.  (Although not visible in the bar ',
                    'chart, the highest risk level includes 3 abandoned wells.)'
                )
            )
        )
    ),
    br(),
    fluidRow(
        column(
            width = 10,
            offset = 1,
            h2('Abandoned wells by district')
        )
    ),
    br(),
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
            width = 8,
            offset = 2,
            img(src = 'shale_gas_lower48.jpg')
        )
    ),
    br(),
    fluidRow(
        column(
            width = 8,
            offset = 2,
            p(
                'The distribution of abandoned wells among RRC districts roughly ',
                'corresponds to geologic regions of Texas.'
            )
        )
    ),
    br(),
    fluidRow(
        column(
            width = 10,
            offset = 1,
            h2('Abandoned wells by county')
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
            width = 8,
            offset = 2,
            p('There are stories behind the concentrations of abandoned wells'),
            tags$ul(
                tags$li(
                    'In Hutchinson County (North Texas), the primary industry ',
                    'since the 1920s has been oil and gas [6], but production has ',
                    'been dropping for decades.  Between 1999 and 2019, gas ',
                    'production and oil production dropped by ',
                    '72% and 60%, respectively [7].'
                ),
                tags$li(
                    'Pecos County (West Texas) has many wells drilled decades ago by ',
                    'wildcatters (speculators who drilled outside of proven areas).',
                    'Wells that didn\'t turn out to be productive were simply ',
                    'abandoned [3, 4].',
                    tags$ul(
                        tags$li(
                            class = 'sub-bullet',
                            'Wildcatters drilled in Pecos county because of its ',
                            'proximity to productive regions of the Permian Basin.  ',
                            'Large regions of Pecos county do not have productive ',
                            'wells, however.'
                        )
                    )
                )
            )
        )
    ),
    br(),
    fluidRow(
        column(
            width = 6,
            offset = 3,
            plotOutput('county_totals_hist')
        )
    ),
    br(),
    fluidRow(
        column(
            width = 6,
            offset = 3,
            p('Most counties have fewer than 50 abandoned wells.')
        )
    ),
    br(),
    fluidRow(
        column(
            width = 10,
            offset = 1,
            h2('How long have wells been abandoned?')
        )
    ),
    fluidRow(
        column(
            width = 6,
            offset = 1,
            plotOutput('inactive_period_texas')
        ),
        column(
            width = 4,
            p('A large number of wells have officially been abandoned since ',
              'Jan 1998.'),
            tags$ul(
                tags$li(
                    'In many cases, little is known about wells that were drilled ',
                    'decades ago [3, 4].'
                ),
                tags$li(
                    'There is an ongoing effort to search for abandoned wells in Texas [3].'
                )
            )
        )
    ),
    br(),
    fluidRow(
        column(
            width = 10,
            offset = 1,
            h2('Abandoned wells inactive at least 20 years')
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
            width = 5,
            offset = 1,
            plotOutput('inactive_period_pecos')
        ),
        column(
            width = 5,
            plotOutput('inactive_period_hutchinson')
        )
    ),
    br(),
    fluidRow(
        column(
            width = 10,
            offset = 1,
            p('A closer look at two counties'),
            tags$ul(
                tags$li(
                    'Unsuccessful exploration by wildcatters has left a concentration of old ',
                    'abandoned wells in Pecos County.'
                ),
                tags$li(
                    'Hutchinson County has a history as an oil boom town dating back ',
                    'to the 1920s [8], and so it is not surprising that it ',
                    'has a number of old abandoned wells.  ',
                    tags$ul(
                        tags$li(
                            class = 'sub-bullet',
                            'The recent history of Hutchinson County\'s decline in oil ',
                            'and gas production is reflected in the distribution of ',
                            'abandoned-well lifetimes.  For instance, the histogram shows that ',
                            'there was a surge in the number of abandoned wells early in 2016.',
                            'The price of crude oil (West Texas Intermediate) dropped steadily ',
                            'during the preceding two years, from ~$100 per barrel early in ',
                            '2014 to ~$30 per barrel early in 2016.  The HAL stock price also ',
                            'reached a low early in 2016 (see the figure higher in the page).'
                        )
                    )
                )
            )
        )
    ),
    br(),
    fluidRow(
        column(
            width = 10,
            offset = 1,
            h2('Conclusion')
        )
    ),
    fluidRow(
        column(
            width = 10,
            offset = 1,
            p(
                style = 'font-size: 165%;',
                'The Railroad Commission of Texas (RRC) has a track record of successfully ',
                'dealing with the problem of abandoned wells in Texas.  The number of ',
                'abandoned wells needing to be plugged has significantly decreased in the past ',
                'fifteen years.'
            ),
            p(
                style = 'font-size: 165%;',
                'The data does show ',
                'a jump in the number of recently abandoned wells, but the increase is ',
                'only a fraction of the size of the RRC\'s persistent backlog of abandoned wells.'

            ),
            p(
                style = 'font-size: 165%;',
                'The lack of progress in reducing this backlog in recent years ',
                'is a concern, particularly since the backlog includes many wells that pose a ',
                'significant risk to health and to the environment.  Given the ',
                'ongoing struggles of the oil and gas industry, the backlog is likely to ',
                'increase unless the RRC is able to increase its rate of plugging abandoned wells.'
            )
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
            tags$ol(
                type = '1',
                tags$li(ny_times_footnote, class = 'footnote'),
                tags$li(study_footnote, class = 'footnote'),
                tags$li(tribune_footnote, class = 'footnote'),
                tags$li(mrt_footnote, class = 'footnote'),
                tags$li(reuters_footnote, class = 'footnote'),
                tags$li(handbook_footnote, class = 'footnote'),
                tags$li(de_footnote, class = 'footnote'),
                tags$li(museum_footnote, class = 'footnote')
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
