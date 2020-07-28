"""Scrape data from The Railroad Commission of Texas (RRC), the agency that
regulates the oil and gas industry.

The goal of the data collection is to investigate the status of abandoned oil
and gas wells in Texas.

Scraped data is saved in subdirectories of a directory named data, which is
created in the working directory if it does not already exist.
"""
# Standard-library imports
from pathlib import Path
import re
import time

# Third-party imports
from bs4 import BeautifulSoup
import requests

# Delay between requests for data from RRC.  Browsing the site shows that the
# it can be slow, so the delay is set to be long.
_DELAY = 5

# The RRC site states that the data is provided for individuals who want
# specific information, rather than for automated data collection.  To avoid
# issues, I am including my current _USER_AGENT with download requests.
_USER_AGENT = 'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:78.0) Gecko/20100101 Firefox/78.0'

# Scraped data is downloaded in subdirectories of _DATA_ROOT.  If the directory
# does not already exist in the working directory, it is created.
_DATA_ROOT = 'data'

# Testing shows that the html strings obtained from RRC using the requests
# module are significantly different than what is obtained by the browser, even
# when user-agent is specified in the request header.  Prettified versions of
# the html programmatically are saved in _SAVED_PAGES inside _DATA_ROOT.  The
# saved html is used to develop detailed scraping commands.
_SAVED_PAGES = 'saved_pages'


def _get(url):
    """Perform repetitive tasks involved executing HTTP GET."""

    headers = {'user-agent': _USER_AGENT}
    r = requests.get(url, headers = headers)
    r.raise_for_status()
    print(f'Successfully downloaded data for\n{url}\n', flush = True)

    # Enforce a delay immediately after performing the request, so that there is
    # no need to worry about this in other parts of the code.
    time.sleep(_DELAY)

    return r


def _check_parents(file_path):
    """Check whether the parents of a file path exist and make them if not."""
    parent = file_path.parents[0]
    parent.mkdir(parents = True, exist_ok = True)


def get_html_string(url):
    """Return the html string for a url, raising an exception if unsuccessful."""
    r = _get(url)
    return r.text


def get_binary_file(url, relative_path):
    """Download and save a binary file, raising an exception if the download is
    unsuccessful.

    Executes HTTP GET and saves the result as a binary file at:

    Path(_DATA_ROOT) / relative_path

    Any missing parents of the file path are created by the function.
    """
    r = _get(url)

    file_path = Path(_DATA_ROOT) / relative_path
    _check_parents(file_path)
    file_path.write_bytes(r.content)


def get_soup(url, filename):
    """Get the BeautifulSoup treep for a url and save prettified version of the html. """
    html_string = get_html_string(url)
    soup = BeautifulSoup(html_string, 'html.parser')
    html_string = soup.prettify()

    file_path = Path(_DATA_ROOT) / _SAVED_PAGES / filename
    _check_parents(file_path)
    file_path.write_text(html_string)

    return soup


def get_cleanup_reports():
    """Scrape reports on efforts to plug and clean up abandoned wells."""

    url = 'https://www.rrc.state.tx.us/oil-gas/environmental-cleanup-programs/oil-gas-regulation-and-cleanup-fund/'
    soup = get_soup(url, 'cleanup_reports.html')


def get_distribution_reports():
    """Scrape reports giving the distribution of wells (including abandoned wells)."""

    url = 'https://www.rrc.state.tx.us/oil-gas/research-and-statistics/well-information/well-distribution-tables-well-counts-by-type-and-status/'
    soup = get_soup(url, 'well_distributions.html')


def get_districts():
    """Scrape a table of RRC districts/district codes and corresponding
    counties/county codes."""

    url = 'https://www.rrc.state.tx.us/about-us/organization-activities/rrc-locations/counties-by-dist/'
    soup = get_soup(url, 'districts.html')


def get_abandoned_wells_report():
    """Download an excel file giving information about abandoned wells that
    currently need to plugged."""

    url = 'https://www.rrc.state.tx.us/oil-gas/research-and-statistics/well-information/orphan-wells-12-months/'
    soup = get_soup(url, 'abandoned_wells.html')


def main():
    """Execute the functions defined in this module to collect data on abandoned
    oil and gas wells."""
    get_cleanup_reports()
    get_distribution_reports()
    get_districts()
    get_abandoned_wells_report()


if __name__ == '__main__':
    main()
