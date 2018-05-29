#!/usr/bin/env python3
# coding: utf8

import sys
from lxml import html

url="https://www.studierendenwerk-aachen.de/speiseplaene/academica-w.html"
week = [
        'montag',
        'dienstag',
        'mittwoch',
        'donnerstag',
        'freitag'
        ]
# Naechste hinzufügen!
week_naechste = [x+'Naechste' for x in week]
cap_week = [x.capitalize() for x in week]
dishes = [
        'Tellergericht',
        'Vegetarisch',
        'Empfehlung des Tages',
        'Klassiker',
        'Pizza des Tages',
        'Pasta',
        'Wok',
        'Burger Classic',
        'Burger des Tages',
        'Fingerfood',
        'Sandwich',
        'Flammengrill',
        'Hauptbeilage',
        'Gemüse/Salat'
        ]
replace_chars = ['\t','\n',' ']

page = html.parse(url)

def get_weekday(add=0):
    import datetime
    today = datetime.date.weekday(datetime.date.today())
    # no food on saturday or sunday
    if today == 6 or today == 7:
        today = 5
    tmp = today+add
    if tmp >= 5:
        naechste = True
    else:
        naechste = False
    while tmp > 4:
        tmp -= 5
    if naechste:
        return week_naechste[tmp],'nächster '+cap_week[tmp]
    else:
        return week[tmp],cap_week[tmp]

# handling argvs
argvs = sys.argv[1:]
# keywords: day: "d{int}", meal: "m{int}"
if len(argvs) > 0:
    for arg in argvs:
        char = str(arg[0])
        try:
            rest = int(arg[1:])
        except ValueError:
            print('ERROR: No <arg> after "%s"' % char)
            raise ValueError
        if char == 'd':
            additional = rest
        elif char == 'm':
            meal = rest
            #if meal > len(dishes):
            #    print('ERROR: Wrong dish')
            #    raise ValueError
try:
    additional
except NameError:
    additional = 0
try:
    meal
except NameError:
    meal = 3

# right one is the <div> element of the weekday
wday,print_wday = get_weekday(add=additional)
# modify 'dishes[0]' on fridays
if wday == 'freitag' or wday == 'freitagNaechste':
    dishes[0] = 'Süßspeise'
for element in page.findall('.//div'):
    if element.get('id') == wday:
        right_one = element


# dish_elements is an array containing all the different dishes of one day
dish_elements = []
for sub in right_one.findall('.//td'):
    if sub.get('class') == 'menue-wrapper':
        dish_elements.append(sub)


def select_dish(dish_type):
    for i in dish_elements:
        for j in i.findall('.//span'):
            if (j.get('class') == 'menue-item menue-category') and (dish_type in j.text):
                return i

def get_dishname(dish_type):
    for k in select_dish(dish_type).findall('.//span'):
        if k.get('class') == 'menue-item menue-desc':
            d_name = k.text
        elif k.get('class') == 'menue-item menue-price':
            d_price = k.text
    return d_name,d_price


try:
    curr_dish = dishes[meal]
except IndexError:
    curr_dish = 'Klassiker'
dname,dprice = get_dishname(curr_dish)
def clear_str(dname):
    new_dname = ''
    for i in range(len(dname)):
        if not ((dname[i] in replace_chars) and (dname[i-1] in replace_chars)):
            new_dname += dname[i]
    return new_dname.replace('\n','')

dname = clear_str(dname)
dprice = clear_str(dprice)

print(print_wday+': '+curr_dish,('(%s)' % dprice)+('\n%s' % dname))

