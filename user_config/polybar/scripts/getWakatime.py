#!/usr/bin/python3

def getClockColor(totalH, multiplier):
    if totalH < 6 * multiplier:
        return "#99FFC2"
    elif totalH >= 6 * multiplier and 9 * multiplier > totalH:
        return "#8DC133"
    elif totalH >= 9 * multiplier and 12 * multiplier > totalH:
        return "#F97B4D"
    elif totalH >= 12 * multiplier and 14 * multiplier > totalH:
        return "#C10B57"
    else:
        return "#8D0601"




import urllib.request, json
with urllib.request.urlopen("https://wakatime.com/share/@35061e46-e6ae-4c54-9981-c98a50bfab17/0674e617-7e65-4143-b88f-848f35e7f359.json") as url:
    data = json.load(url)
    data = data['data']
    sumH = 0
    sumM = 0
    sumS = 0
    for i in data:
        sumS += i['grand_total']['total_seconds']
    sumH = int(round(sumS / 3600, 0))
    sumM = int(round(sumS % 3600 / 60, 0))

    print("%{F#F0C674}7 days%{F-}: %{F" + getClockColor(sumH, 3) + "}"  + str(sumH) + ":" + str(sumM), end="%{F-}")
    print(" %{F#707880}|%{F-} %{F#F0C674}today%{F-}: %{F" + getClockColor(data[len(data) - 1]['grand_total']['hours'], 1) + "}" + data[len(data) - 1]['grand_total']['digital'], end="%{F-}")

with urllib.request.urlopen("https://wakatime.com/share/@35061e46-e6ae-4c54-9981-c98a50bfab17/bec79df7-baae-4ff6-afee-f47571162cf9.json") as url:
    data = json.load(url);
    data = data['data']
    for i in range(0, 3):
        print(" %{F#707880}|%{F-} %{F" + data[i]['color'] + "}" + data[i]['name'] + "%{F-}: %{F" + getClockColor(data[i]['hours'], 3) + "}"  + data[i]['digital'], end="%{F-}")
