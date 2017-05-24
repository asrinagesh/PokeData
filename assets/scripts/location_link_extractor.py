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

url = 'http://bulbapedia.bulbagarden.net/wiki/List_of_routes'

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
table = soup.find_all('table', style='float:left; background:#ABA9A4; border: 2px solid #949391; border-radius: 10px; -moz-border-radius: 10px; -webkit-border-radius: 10px; -khtml-border-radius: 10px; -icab-border-radius: 10px; -o-border-radius: 10px;')

# Find all the <tr> tag pairs, skip the first one, then for each.
for row in table[0].find_all('tr')[3:]:
    # Create a variable of all the <td> tag pairs in each <tr> tag pair,
    col = row.find_all('th')
    # Create a variable of the string inside 3rd <td> tag pair,
    try:
        location = "http://bulbapedia.bulbagarden.net" + col[-1].a.get('href')
    except (IndexError, AttributeError):
        location = col[-1].text.strip()
    # and append it to age variable
    location_name.append(location)

# Deletes the route general names
indexes = [28,49,84,115,139]
for index in sorted(indexes, reverse=True):
    del location_name[index]

big_ass_data = []
for link in location_name:
    pokemon = set()
    r = requests.get(link)
    soup = BeautifulSoup(r.text, 'lxml')
    # All the tables on the html page
    table = soup.find_all('table', align='left')
    for gen in table[0:3]:
        for row in gen.find_all('tr', style="text-align:center;", recursive=False)[0:]:
            name = row.find_all('span')
            # print(link)
            # print(name[1].text)
            # print('\n')
            pokemon.add(name[1].text)
    #print(pokemon)

    # Get map url
    route_name = link.split('/')[-1].replace('_',' ')
    print(route_name)
    img_a = soup.find('img', alt=str(route_name))
    img_url = img_a.get('src')

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
