import requests
from bs4 import BeautifulSoup
from urllib.request import urlopen
from urllib.request import Request
from urllib.request import urlretrieve
import shutil
import re
import os
from os.path import basename
from urllib.parse import urlsplit
from urllib.parse import urlparse
from posixpath import basename,dirname
import ssl

url = 'http://bulbapedia.bulbagarden.net/wiki/List_of_cities_and_towns'

def process_url(raw_url):
 if ' ' not in raw_url[-1]:
     raw_url=raw_url.replace(' ','%20')
     return raw_url
 elif ' ' in raw_url[-1]:
     raw_url=raw_url[:-1]
     raw_url=raw_url.replace(' ','%20')
     return raw_url

# Scrape the HTML at the url
r = requests.get(url)

# Turn the HTML into a Beautiful Soup object
soup = BeautifulSoup(r.text, 'lxml')

# Create four variables to score the scraped data in
location_name = []

# Create an object of the first object that is class=dataframe
table = soup.find_all('table', style='text-align:center; background: #ccf; border: 3px solid blue;')

# Find all the <tr> tag pairs, skip the first one, then for each.
for row in table[0].find_all('tr')[1:]:
    # Create a variable of all the <td> tag pairs in each <tr> tag pair,
    col = row.find_all('td')
    # Create a variable of the string inside 3rd <td> tag pair,
    try:
        location = "http://bulbapedia.bulbagarden.net" + col[0].a.get('href')
    except (IndexError, AttributeError):
        location = col[-1].text.strip()
    # and append it to age variable
    location_name.append(location)

for link in location_name:
    pokemon = set()
    r = requests.get(link)
    soup = BeautifulSoup(r.text, 'lxml')
    # All the tables on the html page
    all_left_tables = soup.find_all('table', align='left')
    for one_table in all_left_tables[0:]:
        if 'style' in one_table.attrs:
            raw_attributes = one_table.attrs['style']
            if '-moz-border-radius' not in raw_attributes:
                pokemon_table = one_table
                break

    try:
        rows_in_poke_table = pokemon_table.find_all('tr', style="text-align:center;", recursive=False)
        for row in pokemon_table.find_all('tr', style="text-align:center;", recursive=False)[0:]:
            name = row.find_all('span')
            pokemon.add(name[1].text)
    except:
        print("No Pokemon in this location.")

    # Get map url
    route_name = link.split('/')[-1].replace('_',' ')
    print(route_name)
    print(pokemon)

    all_tables = soup.find_all('table')

    for one_table in all_tables[0:]:
        if 'style' in one_table.attrs:
            raw_attributes = one_table.attrs['style']
            if 'float:right;' in raw_attributes:
                the_one_and_only = one_table
                break

    map_tr = the_one_and_only.find_all('tr', recursive=False)[-1]

    if map_tr.find('img'):
        img_url = map_tr.find('img').get('src')

    print(img_url)
    print('\n')
    # Setting up downloading image
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    imgurl = process_url(img_url)
    req = Request(imgurl, headers = {'User-Agent': 'Mozilla/5.0'})

    try:
        imgdata = urlopen(req, context=ctx).read()
    except Exception as e:
        print(e)
    for poke in pokemon:
        output=open("./images/" + poke + ".png",'wb')
        output.write(imgdata)
        output.close()
