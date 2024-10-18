import re
import json
import requests
import os
import time
import requests
    
def getProfList(docstring):
    if "Enseignants : " in docstring:
        docstring = docstring.split("Enseignants : ")[1]
    elif "Enseignant : " in docstring:
        docstring = docstring.split("Enseignant : ")[1]
    docstring = docstring.split("\\n\\n")[0]
    return docstring


def get_request(id):
    txt = f"https://enpoche.normandie-univ.fr/aggrss/public/edt/edtProxy.php?edt_url=http://proxyade.unicaen.fr/ZimbraIcs/intervenant/{id}"
    
    while True:
        try:
            response = requests.get(txt)
            if response.status_code == 200 and ('Le projet est invalide' not in response.text):
                return response.text
            return None
        except requests.exceptions.RequestException as e:
            print(f"Request failed: {e}. Retrying...")
            time.sleep(5)

def getProf(ctnt, json):
    dict = {}
    for index, value in enumerate(ctnt.split("BEGIN:VEVENT")):
        if index > 0:
            parsed = getProfList(value).replace("\n ", "").replace("\r", "")
            for item in parsed.split("\\, "):
                if item not in dict:
                    dict[item] = 0
                dict[item] += 1
                
    if dict:
        max_value = max(dict.values())
        max_keys = [key for key, value in dict.items() if value == max_value]
        
        for i in max_keys:
            dataJson = {}
            dataJson['numUniv'] = 1
            dataJson['descTT'] = i
            dataJson['adeUniv'] = "http://proxyade.unicaen.fr/ZimbraIcs/intervenant/"
            dataJson['adeResources'] = file_name
            dataJson['adeProjectId'] = 2024
            json.append(dataJson)
            
        

    
data = {
    
}
data["prof"] = []
count = 0
url = 'https://enpoche.normandie-univ.fr/aggrss/public/edt/edtProxy.php?edt_url=http://proxyade.unicaen.fr/ZimbraIcs/intervenant/?'
response = requests.get(url)
for index, i in enumerate(response.text.split('<tr><td valign="top">')):
    if index != 0 and index != 1:
        i = i.split('</a></td>')[0]
        i = i.split('<a href="')[1]
        i = i.split('">')[1]
        print(count,i)
        text = get_request(i)
        if index % 5000 == 0:
            with open('prof.json', 'w', encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False)
        if text != None:
            getProf(text, data['prof'])
        count+=1
with open('prof.json', 'w', encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False)