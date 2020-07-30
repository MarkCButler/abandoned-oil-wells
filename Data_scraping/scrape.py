"""Scrape data from The Railroad Commission of Texas (RRC), the agency that
regulates the oil and gas industry.

The goal of the data collection is to investigate the status of abandoned oil
and gas wells in Texas.

Scraped data is saved in subdirectories of a directory named data, which is
created in the working directory if it does not already exist.
"""
# Standard-library imports
from pathlib import Path
import pprint
import re
import time

# Third-party imports
from bs4 import BeautifulSoup
import requests

# Import and initialize tika for pdf parsing
import tika
tika.initVM()
from tika import parser

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
# Functions for fetching and saving data
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
# Function to parse and save text data
# from a pdf file
########################################

def parse_pdf(filename, parent):
    """Use tika to parse a pdf file and save the results.

    For a pdf file named Fiscal_Year_2019.pdf, two files are saved:
    Fiscal_Year_2019_metadata.txt, Fiscal_Year_2019_content.txt
    """
    parent = Path(parent)
    pdf_filename = Path(filename)
    metadata_filename = pdf_filename.stem + '_metadata.txt'
    content_filename = pdf_filename.stem + '_parsed.txt'

    # Parse the downloaded pdf.
    pdf_path = str(parent / pdf_filename)
    parsed = parser.from_file(pdf_path)

    # Save the parsed text.  Since parsed['metadata'] is a dictionary, we need
    # to use pprint to get a readable text file.
    with open(parent / metadata_filename, 'w') as metadata_file:
        pprint.pprint(parsed['metadata'], stream = metadata_file,
                      indent = 4, width = 130)

    (parent / content_filename).write_text(parsed['content'])


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
        filename = a_tag.string.strip().replace(' ', '_') +  '.pdf'
        relative_path = annual_reports_dir / filename
        url = _BASE_URL + a_tag['href']
        get_binary_file(url, relative_path)

        parse_pdf(filename,
                  Path(_DATA_ROOT) / annual_reports_dir)


def _has_string(tag):
    """Search function used with find_all in BeautifulSoup."""
    return tag.string


def get_well_distribution_reports():
    """Scrape reports giving the distribution of wells (including abandoned wells)."""

    # Internal function to generate a filename based on the text for an link tag
    # (a tag), if there is text in the tag.  This is needed because a link tag
    # may have no text (i.e., not be visible in the browser), or it may have
    # text included in the tag contents even when tag.string is None.  If the
    # text is included in tag.contents, there may be other junk (such as <br/>)
    # in tag.contents.  Since tag.contents is messy, we need to filter it with
    # the function below.
    def get_filename(tag):
        for element in tag.contents:
            if re.search(r'\d+', str(element)):
                return element.strip().replace(' ', '_').replace(',', '') + '.pdf'
        return None


    url = 'https://www.rrc.state.tx.us/oil-gas/research-and-statistics/well-information/well-distribution-tables-well-counts-by-type-and-status/'
    soup = get_soup(url, 'well_distributions.html')

    distribution_reports_dir = Path('Well_distributions')

    table = soup.table
    rows = table.find_all('tr')
    table_subsections = [{'header': 0, 'data': 1},
                         {'header': 2, 'data': 3}]
    for subsection in table_subsections:
        header_row = rows[subsection['header']]
        year_tags = header_row.find_all(_has_string)
        years = [year_tag.string.strip()
                 for year_tag in year_tags]
        year_dirs = [distribution_reports_dir / year
                     for year in years]

        data_row = rows[subsection['data']]
        cells = data_row.find_all('td')
        for index, cell in enumerate(cells):
            a_tags = cell.find_all('a')
            for a_tag in a_tags:
                # What we want to scrape is the links with text on the page, but
                # some of the a tags in table cells do hot have any text.  These
                # should be skipped.
                #
                # The function get_filename tries to extract string that can be
                # used for the filename, returning none if no relevant text
                # could be found for the tag.  As a result, a tags with no text
                # are skipped.
                filename = get_filename(a_tag)
                if filename:
                    relative_path = year_dirs[index] / filename
                    url = _BASE_URL + a_tag['href']
                    get_binary_file(url, relative_path)


def get_districts():
    """Scrape a table of RRC districts/district codes and corresponding
    counties/county codes."""

    url = 'https://www.rrc.state.tx.us/about-us/organization-activities/rrc-locations/counties-by-dist/'
    soup = get_soup(url, 'districts.html')


def get_abandoned_wells_report():
    """Download an excel file giving information about abandoned wells that
    currently need to plugged."""

    def has_excel_string(tag):
        if tag.string and 'excel version' in tag.string.lower():
            return True
        else:
            return False

    url = 'https://www.rrc.state.tx.us/oil-gas/research-and-statistics/well-information/orphan-wells-12-months/'
    soup = get_soup(url, 'abandoned_wells.html')

    a_tag = soup.find(has_excel_string)
    filename = a_tag['title']
    relative_path = Path('Abandoned_wells') / filename
    url = _BASE_URL + a_tag['href']
    get_binary_file(url, relative_path)



########################################
# Main function
########################################

def main():
    """Execute the functions defined in this module to collect data on abandoned
    oil and gas wells."""
    get_cleanup_reports()
    get_well_distribution_reports()
    get_districts()
    get_abandoned_wells_report()


if __name__ == '__main__':
    main()
