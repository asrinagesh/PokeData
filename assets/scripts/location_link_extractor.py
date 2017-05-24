import requests
from bs4 import BeautifulSoup

url = 'https://wiki.p-insurgence.com/Pok%C3%A9mon_Locations'

# Scrape the HTML at the url
r = requests.get(url)

# Turn the HTML into a Beautiful Soup object
soup = BeautifulSoup(r.text, 'lxml')

# Create four variables to score the scraped data in
location_name = []

# Create an object of the first object that is class=dataframe
table = soup.find(class_='roundy')

# Find all the <tr> tag pairs, skip the first one, then for each.
for row in table.find_all('tr')[1:721]:
    # Create a variable of all the <td> tag pairs in each <tr> tag pair,
    col = row.find_all('td')
    # Create a variable of the string inside 3rd <td> tag pair,
    try:
        location = "https://wiki.p-insurgence.com" + col[-1].a.get('href')
    except (IndexError, AttributeError):
        location = col[-1].text.strip()
    # and append it to age variable
    location_name.append(location)

print(location_name)
