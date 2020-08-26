# abandoned-oil-wells-app

This repo includes Python code for scraping web data on abandoned oil wells in
Texas, together with a web app written in R that presents an analysis of the
scraped data.

The app is hosted at

https://markcbutler.shinyapps.io/abandoned-oil-wells-app/

The choice to scrape and analyze data on abandoned oil wells was motivated by
news reports in July, 2020 predicting a surge in the number of abandoned wells
due to the sudden drop in demand for oil and gas associated with the COVID-19
pandemic.  Will abandonment of wells by bankrupt operators do major harm to
the environment?  The web app aims to shed light on that question by exploring
the current situation in Texas.

The web-scraping module scrape.py was run in August 2020, and the resulting
log, which is in the Scrape_data directory together with the module scrape.py,
gives a quick view of the module's operation.  Web scraping is done using the
Beautiful Soup library together with the requests package.  Text is extracted
from downloaded pdf files using the tika package, and pandas is used to
convert an html table to csv.
