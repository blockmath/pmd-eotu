import re
import os

def loadParseXML(filename : str):
    data = ""
    with open(filename) as file:
        data = file.read().replace('\n', ' ').strip()
    data = data.replace('\t', '')
    data = re.sub('<?xml.*??>', '', data)
    data = data.replace('<AnimData>', '{')
    data = data.replace('</AnimData>', '}')
    data = data.replace('<Anims>', '"Anims": [')
    data = data.replace('</Anims>', ']')
    data = data.replace('<Anim>', '{')
    data = data.replace('</Anim>', '},')
    data = data.replace('<Durations>', '"Durations": [')
    data = data.replace('</Durations>', ']')
    data = data.replace('<Duration>', '')
    data = data.replace('</Duration>', ',')
    data = re.sub(r'<([^>]+)>(.*?)</\1>', r'"\1": \2,', data)
    data = re.sub(', ]', ' ]', data)
    data = re.sub('"Name": ([^,]+)', r'"Name": "\1"', data)
    data = re.sub('"CopyOf": ([^,]+)', r'"CopyOf": "\1"', data)
    data = re.sub('""+', '"', data)
    return data

for poke in os.listdir("sprites/pokemon"):
    filename = "sprites/pokemon/" + poke + "/AnimData.xml"
    newData = loadParseXML(filename)
    filename = "sprites/pokemon/" + poke + "/AnimData.json"
    with open(filename, "w") as file:
        file.write(newData)
