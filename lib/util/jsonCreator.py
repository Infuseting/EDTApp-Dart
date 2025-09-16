from datetime import datetime, timedelta
import requests
import re
import selenium.webdriver
import selenium.webdriver.chrome.options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
from pathlib import Path
import json
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import StaleElementReferenceException, ElementClickInterceptedException, WebDriverException

base_dir = Path(__file__).resolve().parent
for fname in ("prof.json", "salle.json", "univ.json"):
    path = base_dir / fname
    if not path.exists():
        path.write_text(json.dumps({}, ensure_ascii=False, indent=2), encoding="utf-8")

intervenant = "https://enpoche.normandie-univ.fr/aggrss/public/edt/edtProxy.php?edt_url=http://proxyade.unicaen.fr/ZimbraIcs/intervenant/"
etudiant_link = "https://enpoche.normandie-univ.fr/aggrss/public/edt/edtProxy.php?edt_url=http://proxyade.unicaen.fr/ZimbraIcs/etudiant/"

prof_path = base_dir / "prof.json"
salle_path = base_dir / "salle.json"
univ_path = base_dir / "univ.json"
etudiant_path = base_dir / "etudiant.json"

def _load_json(path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        try:
            with path.open("r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return {}

profs = _load_json(prof_path)
salles = _load_json(salle_path)
univ = _load_json(univ_path)
etudiants = _load_json(etudiant_path)




def _print_progress(cur, total, bar_len=40):
    if total <= 0:
        return
    frac = cur / total
    filled = int(round(bar_len * frac))
    bar = '=' * filled + ' ' * (bar_len - filled)
    # overwrite the same line; caller will print newline at the end
    print(f"\rProgression: [{bar}] {cur}/{total}", end='', flush=False)

# Prof
def fetch_and_update_profs():
    file_get_content = requests.get(intervenant).content.decode("utf-8")
    rows = re.findall(r"<tr>(.+?)</tr>", file_get_content, flags=re.S)
    candidate_rows = [r for r in rows if "<td" in r and "ics" in r]
    total_candidates = len(candidate_rows)

    for idx, row in enumerate(candidate_rows, start=1):
        _print_progress(idx, total_candidates)

        cols = re.findall(r"<td(.+?)\/td>", row)
        ics = re.search(r'href="(.+?)"', cols[1]).group(1)
        size = re.search(r'>(.+?)<', cols[3]).group(1)

        def _parse_size_to_bytes(s):
            if not s:
                return 0
            s = s.strip().replace('\xa0', '').replace(' ', '')
            m = re.match(r'^([\d\.,]+)\s*([kKmMgG])?[bB]?$', s)
            if not m:
                try:
                    return int(float(s.replace(',', '.')))
                except ValueError:
                    return 0
            num, unit = m.groups()
            num = float(num.replace(',', '.'))
            unit = (unit or '').lower()
            mult = {'': 1, 'k': 1024, 'm': 1024**2, 'g': 1024**3}[unit]
            return int(num * mult)

        size_bytes = _parse_size_to_bytes(size)
        if size_bytes < 1000:
            continue
        # determine base name of the .ics resource
        base_ics = ics.split('.ics')[0]
        # profs["prof"] may be missing or not a list; handle safely
        prof_list = profs.get("prof") if isinstance(profs, dict) else None
        if not isinstance(prof_list, list):
            prof_list = []
        already_present = False
        for p in prof_list:
            if isinstance(p, dict) and p.get("adeResources") == base_ics:
                already_present = True
                break
        if already_present:
            continue
        ics_url = intervenant + ics
        r = requests.get(ics_url)
        if r.status_code != 200:
            continue
        ics_content = r.content.decode("utf-8")
        it = {}
        vevent = re.findall(r"BEGIN:VEVENT(.+?)END:VEVENT", ics_content, flags=re.S)
        for event in vevent:
            def _extract_field(evt, name):
                # match field with optional parameters and folded continuation lines
                m = re.search(rf'(?im)^{name}(?:;[^:]+)*:(.*(?:\r?\n[ \t].*)*)', evt)
                if not m:
                    return ""
                val = m.group(1)
                # unfold folded lines (lines beginning with space or tab)
                val = re.sub(r'\r?\n[ \t]+', '', val)
                # unescape common escapes
                val = val.replace('\\n', '\n').replace('\\,', ',').replace('\\;', ';')
                return val.strip()

            uid = _extract_field(event, "UID")
            dtstart = _extract_field(event, "DTSTART")
            dtend = _extract_field(event, "DTEND")
            summary = _extract_field(event, "SUMMARY")
            location = _extract_field(event, "LOCATION")
            description = _extract_field(event, "DESCRIPTION")

            def _parse_dt(s):
                if not s:
                    return None
                s = s.strip()
                # remove trailing Z if present (UTC designator)
                if s.endswith('Z'):
                    s = s[:-1]
                # if there are parameters like TZID they were removed by _extract_field
                try:
                    if re.match(r'^\d{8}T\d{6}$', s):
                        return datetime.strptime(s, "%Y%m%dT%H%M%S")
                    if re.match(r'^\d{8}$', s):
                        return datetime.strptime(s, "%Y%m%d")
                    # fallback: try generic parse with seconds optional
                    return datetime.strptime(s, "%Y%m%dT%H%M")
                except Exception:
                    return None

            dtstart_obj = _parse_dt(dtstart)
            dtend_obj = _parse_dt(dtend)
            desc_lines = [ln.strip() for ln in description.splitlines() if ln.strip()]
            parsed = {"salle": "", "groupes_activite": "", "enseignant": "", "groupes_etudiants": "", "other": []}

            for ln in desc_lines:
                m = re.match(r'^\s*([^:]+?)\s*:\s*(.+)$', ln)
                if not m:
                    parsed["other"].append(ln)
                    continue
                key, val = m.group(1).strip().lower(), m.group(2).strip()
                # simple accent-insensitive matching
                key_norm = key.replace('é', 'e').replace('è', 'e').replace('ê', 'e').replace('à', 'a').replace('ç', 'c').replace('ô', 'o')
                if 'salle' in key_norm:
                    parsed["salle"] = val
                elif 'groupe' in key_norm and 'activ' in key_norm:
                    parsed["groupes_activite"] = val
                elif 'enseign' in key_norm:
                    parsed["enseignant"] = val
                elif 'groupe' in key_norm and ('etudiant' in key_norm or 'etudiants' in key_norm):
                    parsed["groupes_etudiants"] = val
                else:
                    parsed["other"].append(f"{m.group(1)}: {val}")
                    
                    
            
            it[parsed['enseignant']] = it.get(parsed['enseignant'], 0) + 1
            

        events_total = sum(v for k, v in it.items() if k and k.strip())
        chosen = ""
        if events_total > 10:
            items = [(k.strip(), v) for k, v in it.items() if k and k.strip()]
            if items:
                top_name, top_count = max(items, key=lambda kv: kv[1])
                if top_count / events_total > 0.5:
                    chosen = top_name

        
        chosen = chosen.strip()
        
        if chosen != "":
        
            
            profId = {
                "numUniv": 1,
                "descTT": chosen,
                "adeUniv": "http://proxyade.unicaen.fr/ZimbraIcs/intervenant/",
                "adeResources": int(base_ics),
                "adeProjectId": 2024
            }
                
                
            profs['prof'] = profs.get('prof', [])
            profs['prof'].append(profId)

    # finish progress line and print newline
    _print_progress(total_candidates, total_candidates)
    print()
    prof_path.write_text(json.dumps(profs, ensure_ascii=False, indent=2), encoding="utf-8")

# Salle 
def fetch_and_update_salles():
    ade_publish_url = "https://ade.unicaen.fr/direct/index.jsp?login=visu&password=visu&projectId=2025"
    options = selenium.webdriver.chrome.options.Options()
    #options.add_argument('--headless=new')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    driver = selenium.webdriver.Chrome(options=options)
    driver.get(ade_publish_url)
    wait = WebDriverWait(driver, 100000)
    
    # Get on ade page
    button = wait.until(EC.element_to_be_clickable((By.XPATH, '//*[@id="x-auto-14"]')))
    button.click()
    wait.until(EC.presence_of_element_located((By.XPATH, '/html/body/div[2]/div[2]/div[1]/div/div/div/div/div[2]/table/tbody/tr/td[1]/table/tbody/tr/td[2]/table/tbody/tr[2]/td[2]/em/button')))
    button = driver.find_element(By.XPATH, '/html/body/div[2]/div[2]/div[1]/div/div/div/div/div[2]/table/tbody/tr/td[1]/table/tbody/tr/td[2]/table/tbody/tr[2]/td[2]/em/button')
    button.click()
    
    
    button = wait.until(EC.presence_of_element_located((By.XPATH, '/html/body/div[1]/div[1]/div/div[2]/div[2]/div[1]/div/div[1]/div/div[2]/div[1]/div[2]/div/div[3]/table/tbody/tr/td[2]/div/div/div/img[2]')))
    button.click()
    
    index=int(input("Enter starting index (1 for first salle): ") or "1")
    time.sleep(2)
    while wait.until(EC.presence_of_element_located((By.XPATH, f'/html/body/div[1]/div[1]/div/div[2]/div[2]/div[1]/div/div[1]/div/div[2]/div[1]/div[2]/div/div[{index}]/table/tbody/tr/td[2]/div/div/div/span[2]'))).text != "Equipements":
        button = wait.until(EC.presence_of_element_located((By.XPATH, f'/html/body/div[1]/div[1]/div/div[2]/div[2]/div[1]/div/div[1]/div/div[2]/div[1]/div[2]/div/div[{index}]/table/tbody/tr/td[2]/div/div/div/img[2]')))
        try:
            ActionChains(driver).send_keys(Keys.ESCAPE).perform()
            time.sleep(0.2)
        except Exception:
            pass

        try:
            ActionChains(driver).move_to_element(button).move_by_offset(5, 5).perform()
            time.sleep(0.2)
        except Exception:
            try:
                driver.execute_script("document.body.dispatchEvent(new MouseEvent('mousemove', {clientX:1, clientY:1}));")
            except Exception:
                pass
        
        try:
            # try smooth scroll into view and center the element
            driver.execute_script(
                "arguments[0].scrollIntoView({behavior: 'smooth', block: 'center', inline: 'nearest'});",
                button,
            )
            time.sleep(0.4)
            try:
                ActionChains(driver).move_to_element(button).pause(0.05).perform()
            except Exception:
                pass
        except Exception:
            # fallback: scroll to the element's y coordinate (no smooth)
            try:
                y = None
                try:
                    y = button.location['y']
                except Exception:
                    try:
                        y = button.rect.get('y')
                    except Exception:
                        y = None
                if y is not None:
                    driver.execute_script("window.scrollTo(0, Math.max(0, arguments[0] - 120));", y)
                    time.sleep(0.2)
            except Exception:
                pass
        
        if button.get_attribute("src").endswith("clear.gif"):
            salleName = wait.until(EC.presence_of_element_located((By.XPATH, f'/html/body/div[1]/div[1]/div/div[2]/div[2]/div[1]/div/div[1]/div/div[2]/div[1]/div[2]/div/div[{index}]/table/tbody/tr/td[2]/div/div/div/span[2]'))).text
            button0 = wait.until(EC.presence_of_element_located((By.XPATH, f'/html/body/div[1]/div[1]/div/div[2]/div[2]/div[1]/div/div[1]/div/div[2]/div[1]/div[2]/div/div[{index}]/table/tbody/tr/td[2]/div/div/div')))
            button0.click()
            
            button1 = wait.until(EC.presence_of_element_located((By.XPATH, f'/html/body/div[1]/div[1]/div/div[2]/div[2]/div[1]/div/div[1]/div/div[2]/div[1]/div[2]/div/div[{index}]/table/tbody/tr/td[2]/div/div/div/img[2]')))
            button1.click()
            button2 = wait.until(EC.presence_of_element_located((By.XPATH, '/html/body/div[1]/div[1]/div/div[3]/div[2]/div[1]/div/table/tbody/tr/td[1]/table/tbody/tr/td[2]/table/tbody/tr[2]/td[2]')))
            def click_all_descendants(root, max_iters=50):
                seen = set()
                iters = 0
                while iters < max_iters:
                    iters += 1
                    try:
                        candidates = root.find_elements(By.XPATH, ".//*")
                    except StaleElementReferenceException:
                        candidates = []
                    new_clicked = False
                    for el in candidates:
                        try:
                            eid = getattr(el, "id", None) or el.id
                            if eid in seen:
                                continue
                            # try to click only if element is displayed and enabled
                            try:
                                if not el.is_displayed():
                                    seen.add(eid)
                                    continue
                            except StaleElementReferenceException:
                                continue
                            # attempt click (ActionChains first, then JS fallback)
                            try:
                                ActionChains(driver).move_to_element(el).pause(0.05).click(el).perform()
                            except (ElementClickInterceptedException, WebDriverException):
                                try:
                                    driver.execute_script("arguments[0].click();", el)
                                except Exception:
                                    # not clickable, mark and skip
                                    seen.add(eid)
                                    continue
                            time.sleep(0.1)
                            seen.add(eid)
                            new_clicked = True
                        except StaleElementReferenceException:
                            continue
                    if not new_clicked:
                        break

            click_all_descendants(button2)
            try:
                ActionChains(driver).move_to_element(button2).move_by_offset(5, 5).pause(0.2).perform()
                time.sleep(0.2)
            except Exception:
                try:
                    driver.execute_script(
                        "arguments[0].dispatchEvent(new MouseEvent('mouseover', {bubbles:true, cancelable:true, view:window}));",
                        button2,
                    )
                    time.sleep(0.2)
                except Exception:
                    pass
            button3 = wait.until(EC.element_to_be_clickable((By.XPATH, "//button[contains(@class,'x-btn-text') and contains(normalize-space(.),'Générer URL')]")))
            try:
                button3.click()
            except Exception:
                button3 = wait.until(EC.element_to_be_clickable((By.XPATH, "//button[contains(@class,'x-btn-text') and contains(.,'Générer')]")))
                button3.click()
            # try to get the generated link safely (href preferred, fallback to text)
            try:
                link = wait.until(EC.presence_of_element_located((By.XPATH, '//div[@id="logdetail"]/a')))
            except Exception:
                try:
                    link = driver.find_element(By.XPATH, '//div[@id="logdetail"]/a')
                except Exception:
                    link = None

            iCal = ""
            if link is not None:
                try:
                    iCal = (link.get_attribute("href") or link.text or "").strip()
                except Exception:
                    try:
                        iCal = (link.text or "").strip()
                    except Exception:
                        iCal = ""

            # extract parameters without requiring a trailing ampersand
            m_res = re.search(r'resources=([^&]+)', iCal)
            m_proj = re.search(r'projectId=([^&]+)', iCal)
            salle_data = {
                "numUniv" : 1,
                "descTT" : salleName,
                "adeUniv": "https://ade.unicaen.fr/jsp/custom/modules/plannings/anonymous_cal.jsp",
                "adeResources": m_res.group(1) if m_res else "",
                "adeProjectId": m_proj.group(1) if m_proj else ""
            }
            salles['salle'] = salles.get('salle', [])
            salles['salle'].append(salle_data)
            print(f"\nAdded salle: {salleName}")
            salle_path.write_text(json.dumps(salles, ensure_ascii=False, indent=2), encoding="utf-8")
            for i in range(0, 4+1):
                if i < 5:
                    try:
                        ActionChains(driver).send_keys(Keys.ESCAPE).perform()
                    except Exception:
                        try:
                            driver.execute_script("document.dispatchEvent(new KeyboardEvent('keydown', {key: 'Escape'}));")
                        except Exception:
                            pass
                    time.sleep(0.2)
        else:
            button.click()
    
        index += 1
        time.sleep(1)

def fetch_and_update_students():
    logged =False
    file_get_content = requests.get(etudiant_link).content.decode("utf-8")
    rows = re.findall(r"<tr>(.+?)</tr>", file_get_content, flags=re.S)
    candidate_rows = [r for r in rows if "<td" in r and "ics" in r]
    total_candidates = len(candidate_rows)
    options = selenium.webdriver.chrome.options.Options()
    options.add_argument('--headless=new')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    driver = selenium.webdriver.Chrome(options=options)
    
    for idx, row in enumerate(candidate_rows, start=1):
        _print_progress(idx, total_candidates)

        cols = re.findall(r"<td(.+?)\/td>", row)
        ics = re.search(r'href="(.+?)"', cols[1]).group(1)
        size = re.search(r'>(.+?)<', cols[3]).group(1)

        def _parse_size_to_bytes(s):
            if not s:
                return 0
            s = s.strip().replace('\xa0', '').replace(' ', '')
            m = re.match(r'^([\d\.,]+)\s*([kKmMgG])?[bB]?$', s)
            if not m:
                try:
                    return int(float(s.replace(',', '.')))
                except ValueError:
                    return 0
            num, unit = m.groups()
            num = float(num.replace(',', '.'))
            unit = (unit or '').lower()
            mult = {'': 1, 'k': 1024, 'm': 1024**2, 'g': 1024**3}[unit]
            return int(num * mult)

        size_bytes = _parse_size_to_bytes(size)
        if size_bytes < 50:
            continue
        # determine base name of the .ics resource
        base_ics = ics.split('.ics')[0]
        # profs["prof"] may be missing or not a list; handle safely
        prof_list = profs.get("prof") if isinstance(profs, dict) else None
        if not isinstance(prof_list, list):
            prof_list = []
        already_present = False
        for p in prof_list:
            if isinstance(p, dict) and p.get("adeResources") == base_ics:
                already_present = True
                break
        if already_present:
            continue
        ics_url = etudiant_link + ics
        print(f"\nProcessing student ICS: {ics_url}")
        r = requests.get(ics_url)
        if r.status_code != 200:
            continue
        ics_content = r.content.decode("utf-8")
        it = {}
        edtel = re.findall(r'EDTEL-(.+?)//', ics_content, flags=re.S)[0]
        driver.get(f"https://webmail.unicaen.fr/")
        wait = WebDriverWait(driver, 2)
        if not logged:
            try:
                
                username = wait.until(EC.presence_of_element_located((By.XPATH, '//*[@id="username"]')))
                username.send_keys("serret241")
                password = wait.until(EC.presence_of_element_located((By.XPATH, '//*[@id="password"]')))
                password.send_keys("Axthux001&")
                button = wait.until(EC.element_to_be_clickable((By.XPATH, '//input[@type="submit"]')))
                button.click()
                logged = True
            except Exception as e:
                pass
        full_name = ""
        try:
            
            newmail = wait.until(EC.presence_of_element_located((By.XPATH, f'//div[@aria-label="Nouveau message"]')))
            newmail.click()
            
            sender = wait.until(EC.presence_of_element_located((By.XPATH, '//input[@aria-label="Adresse À"]')))
            sender.send_keys(f"{edtel}")
            
            liste = wait.until(EC.presence_of_element_located((By.XPATH, '//*[@id="zac__COMPOSE-1_table"]')))
            user = liste.get_attribute("innerHTML")
            m = re.search(r'<td>"(.*?)" &lt;', user)
            if m:
                full_name = m.group(1).strip()
        except:
            pass
        if full_name != "":
            etudiant_data = {
                "numUniv" : 1,
                "descTT" : full_name,
                "adeUniv": "https://ade.unicaen.fr/jsp/custom/modules/plannings/anonymous_cal.jsp",
                "adeResources": ics,
                "adeProjectId": 2023
            }
            print(f"Adding student: {full_name} with EDTEL: {edtel}")
            etudiants['etudiants'] = etudiants.get('etudiants', [])
            etudiants['etudiants'].append(etudiant_data)
            etudiant_path.write_text(json.dumps(etudiants, ensure_ascii=False, indent=2), encoding="utf-8")
            
        


if __name__ == "__main__":
    #fetch_and_update_profs()
    #fetch_and_update_salles()     
    fetch_and_update_students()
    