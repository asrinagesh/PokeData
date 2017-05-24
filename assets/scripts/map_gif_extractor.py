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

## function that processes url, if there are any spaces it replaces with '%20' ##
def process_url(raw_url):
 if ' ' not in raw_url[-1]:
     raw_url=raw_url.replace(' ','%20')
     return raw_url
 elif ' ' in raw_url[-1]:
     raw_url=raw_url[:-1]
     raw_url=raw_url.replace(' ','%20')
     return raw_url

os.mkdir("images/gifs")
os.chdir("images/gifs")

# location_names -> links for location names
location_names = ['']
pokeid = 1
file = open("nomappoke.txt","w")
file.write("poke_id, alt_location\n")

for link in location_names:
    if link.startswith("https"):
        parse_object = urlparse(link)

        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        req = Request(link, headers = {'User-Agent': 'Mozilla/5.0'})
        urlcontent = urlopen(req, context = ctx).read().decode('utf-8')

        imgurls = re.findall('img .*?src="(.*gif|png)"', urlcontent)

        print(link)
        print(imgurls)
        imgurl = process_url('https://wiki.p-insurgence.com' + imgurls[0])
        req = Request(imgurl, headers = {'User-Agent': 'Mozilla/5.0'})
        print(pokeid)
        print(imgurl)
        try:
            imgdata =urlopen(req, context=ctx).read()
        except Exception as e:
            print(e)
        output=open(str(pokeid) + ".gif",'wb')
        output.write(imgdata)
        output.close()
        print("lol")
    else:
        file.write(str(pokeid) + "," + link + "\n")

    pokeid += 1

file.close()
