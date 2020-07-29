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

# _BASE_URL is prepended to relative urls in following links.
_BASE_URL = 'https://www.rrc.state.tx.us'

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

########################################
# Functions that get fetch/save data
########################################

def _get(url):
    """Perform repetitive tasks for executing HTTP GET."""

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

########################################
# URL-specific scraping functions
########################################

# Unlike the html available from the browser as the page source, the html
# obtained using the requests module has few attributes that can be used to
# select individual tags.  Here is a typical example:
#
# <h3>
#  <a id="OCP_quarterly">
#  </a>
#  Oilfield Cleanup Program Quarterly Reports
# </h3>
# <table height="44" width="752">
#  <tbody>
#   <tr>
#    <td>
#     <strong>
#      FY 2020
#     </strong>
#    </td>
#    ...
#
# So in locating relevant tags, a natural approach is to start from one of the
# few tags with an id attribute and then navigate to the tag(s) to be scraped.
# This approach is used in the functions below.

def get_cleanup_reports():
    """Scrape reports on efforts to plug and clean up abandoned wells."""

    url = 'https://www.rrc.state.tx.us/oil-gas/environmental-cleanup-programs/oil-gas-regulation-and-cleanup-fund/'
    soup = get_soup(url, 'cleanup_reports.html')

    header = soup.find(id = 'OCP_quarterly').parent
    _get_quarterly_reports(header)

    header = soup.find(id = 'OCP_annual').parent
    _get_annual_reports(header)

# The helper functions _get_quarterly reports and _get_annual_reports could be
# defined as inner functions of get_cleanup_reports, but they are instead
# defined at internal module functions in order to keep all functions relatively
# short and readable.

def _get_quarterly_reports(header):
    table = header.find_next_sibling()
    rows = table.find_all('tr')

    # Create a list of subdirectories in which the quarterly reports for an
    # individual year will be stored.
    year_tags = rows[0].find_all(_has_string)
    years = [year_tag.string.strip().replace(' ', '_')
             for year_tag in year_tags]
    quarterly_reports_dir = Path('Cleanup_reports') / 'Quarterly'
    year_dirs = [quarterly_reports_dir / year
                 for year in years]

    # Download and save the quarterly reports.  The filenames are inconsistent
    # for different years.  The text of the a tags that link to the reports is
    # used to generate consistent, understandable filenames.
    for row in rows[1:]:
        cells = row.find_all('td')
        for index, cell in enumerate(cells):
            a_tag = cell.find('a')
            if a_tag:
                filename = a_tag.string.strip().replace(' ', '_') + '.pdf'
                relative_path = year_dirs[index] / filename
                url = _BASE_URL + a_tag['href']
                get_binary_file(url, relative_path)


def _get_annual_reports(header):
    table = header.find_next_sibling()
    annual_reports_dir = Path('Cleanup_reports') / 'Annual'
    a_tags = table.find_all('a')
    for a_tag in a_tags:
        filename = a_tag.string.strip().replace(' ', '_') + '.pdf'
        relative_path = annual_reports_dir / filename
        url = _BASE_URL + a_tag['href']
        get_binary_file(url, relative_path)


def _has_string(tag):
    """Search function used with find_all in BeautifulSoup."""
    return tag.string

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

########################################
# Main function
########################################

def main():
    """Execute the functions defined in this module to collect data on abandoned
    oil and gas wells."""
    get_cleanup_reports()
    get_distribution_reports()
    get_districts()
    get_abandoned_wells_report()


if __name__ == '__main__':
    main()
