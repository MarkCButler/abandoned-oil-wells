# abandoned-wells-app

This repo includes Python code for scraping web data on abandoned oil wells in
Texas, together with a web app written in R that analyzes the scraped data.

The app is hosted at



The web-scraping module scrape.py was run in August 2020, and the resulting
log, which is in the Data_scraping directory together with the module, gives a
quick view of the module's operation.  Web scraping is done using the
Beautiful Soup library together with the requests package.  Text is extracted
from downloaded pdf files using the tika package, and pandas is used for
converting an html table to csv.

