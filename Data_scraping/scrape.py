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

_DATA_ROOT = 'data'


def _get(url):
    """Perform repetitive tasks involved in fetching data from a url."""

    headers = {'user-agent': _USER_AGENT}
    r = requests.get(url, headers = headers)
    r.raise_for_status()
    print(f'Successfully downloaded data for\n{url}\n', flush = True)

    # Enforce a delay immediately after performing the request, so that there is
    # no need to worry about this in other parts of the code.
    time.sleep(_DELAY)

    return r


def get_html(url):
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

    # The parent directory must be created before the file is saved.
    parent = file_path.parents[0]
    parent.mkdir(parents = True, exist_ok = True)

    file_path.write_bytes(r.content)


def get_cleanup_reports():
    """Scrape reports on efforts to plug and clean up abandoned wells."""

    url = 'https://www.rrc.state.tx.us/oil-gas/environmental-cleanup-programs/oil-gas-regulation-and-cleanup-fund/'
    html_string = get_html(url)
    # DEBUG CODE: Save copy of html string for testing.
    Path('reports.txt').write_text(html_string)


def get_distribution_reports():
    """Scrape reports giving the distribution of wells (including abandoned wells)."""

    url = 'https://www.rrc.state.tx.us/oil-gas/research-and-statistics/well-information/well-distribution-tables-well-counts-by-type-and-status/'
    html_string = get_html(url)
    # DEBUG CODE: Save copy of html string for testing.
    Path('distributions.txt').write_text(html_string)


def get_districts():
    """Scrape a table of RRC districts/district codes and corresponding
    counties/county codes."""

    url = 'https://www.rrc.state.tx.us/about-us/organization-activities/rrc-locations/counties-by-dist/'
    html_string = get_html(url)
    # DEBUG CODE: Save copy of html string for testing.
    Path('districts.txt').write_text(html_string)


def get_abandoned_wells_report():
    """Download an excel file giving information about abandoned wells that
    currently need to plugged."""

    url = 'https://www.rrc.state.tx.us/oil-gas/research-and-statistics/well-information/orphan-wells-12-months/'
    html_string = get_html(url)
    # DEBUG CODE: Save copy of html string for testing.
    Path('abandoned_wells.txt').write_text(html_string)


def main():
    """Execute the functions defined in this module to collect data on abandoned
    oil and gas wells."""
    get_cleanup_reports()
    get_distribution_reports()
    get_districts()
    get_abandoned_wells_report()


if __name__ == '__main__':
    main()
