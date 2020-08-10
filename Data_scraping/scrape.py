"""Scrape data from The Railroad Commission of Texas (RRC), the agency that
regulates the oil and gas industry.

The goal of the data collection is to investigate the status of abandoned oil
and gas wells in Texas.

Scraped data is saved in subdirectories of a directory named data, which is
created in the working directory if it does not already exist.
"""
# Standard-library imports
import logging
from pathlib import Path
import pprint
import re
import sys
import time

# Third-party imports
from bs4 import BeautifulSoup
import pandas as pd
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
    try:
        r.raise_for_status()
    except requests.HTTPError:
        message = f'Failed to download\n{url}\n\nHTTP response:\n\n{r.text}\n'
        logging.error(message)
        # This raise should be caught by the highest function in the stack that
        # is concerned with processing data from the url.
        raise
    else:
        logging.info(f'Successfully downloaded data for\n{url}\n')

    # Enforce a delay immediately after performing the request, so that there is
    # no need to worry about this in other parts of the code.
    time.sleep(_DELAY)

    return r


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
    try:
        r = _get(url)
    except requests.HTTPError:
        return

    file_path = Path(_DATA_ROOT) / relative_path
    _check_parents(file_path)
    file_path.write_bytes(r.content)
    logging.info(f'Saved binary data to\n{file_path}\n')

    if file_path.suffix == '.pdf':
        parse_pdf(file_path)


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

def parse_pdf(file_path):
    """Use tika to parse a pdf file and save the results.

    If text is successfully extracted from the pdf file, two files are saved,
    one containing metadata for the pdf file and other containing the extracted
    text content.

    For a pdf file named Fiscal_Year_2019.pdf, the filenames for saved metadata
    and text content are Fiscal_Year_2019_metadata.txt,
    Fiscal_Year_2019_content.txt
    """
    parent = file_path.parent
    metadata_filename = file_path.stem + '_metadata.txt'
    content_filename = file_path.stem + '_parsed.txt'

    # Parse the downloaded pdf.
    logging.info(f'Attempting to extract text content from pdf file\n{file_path}\n')
    parsed = parser.from_file(str(file_path))

    if parsed['content']:

        # Save the parsed text.  Since parsed['metadata'] is a dictionary, we need
        # to use pprint to get a readable text file.
        with open(parent / metadata_filename, 'w') as metadata_file:
            pprint.pprint(parsed['metadata'], stream = metadata_file,
                          indent = 4, width = 130)

        parsed_content_path = parent / content_filename
        parsed_content_path.write_text(parsed['content'])
        logging.info(f'Saved parsed text to\n{parsed_content_path}\n')

    else:
        logging.info(f'No text content found in pdf file\n{file_path}\n')


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

def get_districts():
    """Scrape a table of RRC districts/district codes and corresponding
    counties/county codes."""

    url = 'https://www.rrc.state.tx.us/about-us/organization-activities/rrc-locations/counties-by-dist/'
    try:
        soup = get_soup(url, 'districts.html')
    except requests.HTTPError:
        return

    table_html = str(soup.table)
    # The try block attempts to extract a data frame of RRC district codes,
    # which are needed for the choropleth map in the web app.
    try:
        df = pd.read_html(table_html)[0]

        # Set the first row to be the column names.
        df.rename(columns = df.iloc[0], inplace = True)
        df.drop(index = 0, inplace = True)

        to_concat = []
        for start_col in range(0, 12, 4):
            end_col = start_col + 4
            sub_df = df.iloc[:, start_col:end_col]
            # Set the first column to be the index.
            sub_df.set_index('County', drop = True, inplace = True)
            to_concat.append(sub_df)
        df = pd.concat(to_concat, axis = 0)

        # Because of the way the html table was formatted, one of the concatenated
        # dataframes has a row of missing data.
        df.dropna(axis = 0, inplace = True)

        # Drop the column giving district offices.
        df.drop(columns = 'District Office', inplace = True)

    except:
        message = f'Failed to extract data frame of RRC district codes from\n{url}\n'
        logging.error(message)
    else:
        message = f'Successfully extracted data frame of RRC district codes from\n{url}\n'
        logging.info(message)

        file_path = Path(_DATA_ROOT) / 'district_codes' / 'RRC_district_codes.csv'
        _check_parents(file_path)
        df.to_csv(file_path)
        logging.info(f'Saved table of RRC district codes to\n{file_path}\n')


def get_cleanup_reports():
    """Scrape reports on efforts to plug and clean up abandoned wells."""

    url = 'https://www.rrc.state.tx.us/oil-gas/environmental-cleanup-programs/oil-gas-regulation-and-cleanup-fund/'
    try:
        soup = get_soup(url, 'cleanup_reports.html')
    except requests.HTTPError:
        return

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
    year_tags = rows[0].find_all(
        # Tests whether a tag is type 'td' and also has a string
        lambda tag: tag.string if tag.name == 'td' else False
        )
    years = [year_tag.string.strip().replace(' ', '_')
             for year_tag in year_tags]
    quarterly_reports_dir = Path('cleanup_reports') / 'quarterly'
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
    annual_reports_dir = Path('cleanup_reports') / 'annual'
    a_tags = table.find_all('a')
    for a_tag in a_tags:
        filename = a_tag.string.strip().replace(' ', '_') +  '.pdf'
        relative_path = annual_reports_dir / filename
        url = _BASE_URL + a_tag['href']
        get_binary_file(url, relative_path)


def get_well_distribution_reports():
    """Scrape reports giving the distribution of wells (including abandoned wells)."""

    # Internal function to generate a filename based on the text for an link tag
    # (<a ...>), if there is text in the tag.  This is needed because a link tag
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
    try:
        soup = get_soup(url, 'well_distributions.html')
    except requests.HTTPError:
        return

    distribution_reports_dir = Path('well_distributions')

    # The links to monthly reports on well distribution are organized into a
    # table.  The first and third row of the table are headings corresponding to
    # distinct years.  However, not all yearly headings are correct.  (For
    # example, the heading for 2012 corresponds to annual reports for 2011.)
    #
    # Rather than using the headings to organize the downloaded files into
    # different subdirectories, I will extract all links in the table and then use
    # regular expressions to sort them into subdirectories based on year.
    a_tags = soup.table.find_all('a')
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
            year = re.search(r'(\d{4})\.', filename).group(1)
            relative_path = distribution_reports_dir / year / filename
            url = _BASE_URL + a_tag['href']
            get_binary_file(url, relative_path)


def get_abandoned_wells_report():
    """Download an excel file giving information about abandoned wells that
    currently need to plugged."""

    def has_excel_string(tag):
        if tag.string and 'excel version' in tag.string.lower():
            return True
        else:
            return False

    url = 'https://www.rrc.state.tx.us/oil-gas/research-and-statistics/well-information/orphan-wells-12-months/'
    try:
        soup = get_soup(url, 'abandoned_wells.html')
    except requests.HTTPError:
        return

    a_tag = soup.find(has_excel_string)
    filename = a_tag['title']
    relative_path = Path('abandoned_wells') / filename
    url = _BASE_URL + a_tag['href']
    get_binary_file(url, relative_path)


########################################
# Utility functions
########################################

def _check_parents(file_path):
    """Check whether the parents of a file path exist and make them if not."""
    parent = file_path.parents[0]
    parent.mkdir(parents = True, exist_ok = True)


def _initialize_logging():
    """Configure logging to go to a log file as well as to stdout.

    Print a message to stdout giving the location of the log file.
    """
    log_file = Path(_DATA_ROOT) / 'scrape.log'
    _check_parents(log_file)
    file_handler = logging.FileHandler(filename = str(log_file), mode = 'w')
    console_handler = logging.StreamHandler(sys.stdout)
    logging.basicConfig(level = logging.INFO,
                        format = '%(levelname)s: %(message)s',
                        handlers=[file_handler, console_handler])
    print(f'A log is being saved to {log_file} as well as printed to screen.\n')


########################################
# Main function
########################################

def main():
    """Execute the functions defined in this module to collect data on abandoned
    oil and gas wells."""
    _initialize_logging()
    get_districts()
    get_cleanup_reports()
    get_well_distribution_reports()
    get_abandoned_wells_report()

if __name__ == '__main__':
    main()
