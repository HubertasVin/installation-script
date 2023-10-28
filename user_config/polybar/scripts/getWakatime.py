#!/usr/bin/python3

import urllib.request, json
with urllib.request.urlopen("https://wakatime.com/share/@35061e46-e6ae-4c54-9981-c98a50bfab17/0674e617-7e65-4143-b88f-848f35e7f359.json") as url:
    data = json.load(url)
    sumH = 0
    sumM = 0
    sumS = 0
    for i in data['data']:
        sumS += i['grand_total']['total_seconds']
    sumH = int(round(sumS / 3600, 0))
    sumM = int(round(sumS % 3600 / 60, 0))
    print("7 days: " + str(sumH) + ":" + str(sumM), end="")
    print(" | today: " + data['data'][6]['grand_total']['digital'], end="")

with urllib.request.urlopen("https://wakatime.com/share/@35061e46-e6ae-4c54-9981-c98a50bfab17/bec79df7-baae-4ff6-afee-f47571162cf9.json") as url:
    data = json.load(url);
    print(" | " + data['data'][0]['name'] + ": " + data['data'][0]['digital'], end="")
    print(" | " + data['data'][1]['name'] + ": " + data['data'][1]['digital'], end="")
    print(" | " + data['data'][2]['name'] + ": " + data['data'][2]['digital'], end="")
