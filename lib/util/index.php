<?php
function parse_event_data($docstring, $adeBase) {
    $data = explode("\n", trim($docstring));
    $event_data = [];
    $tempKey = '';
    $stop = 0;
    foreach ($data as $lines) {
        $line = explode("(Exporté le:", $lines)[0];
        
        if (strpos($line, ":") !== false && preg_match('/^(DTSTART|DTEND|SUMMARY|LOCATION|DESCRIPTION|UID|CREATED|END|SEQUENCE|DTSTAMP|LAST-MODIFIED)/', $line)) {
            list($key, $value) = explode(":", $line, 2);
            $tempKey = $key;
            $stop = 0;
            $keyParts = explode(";", $key);
            
            $key = $keyParts[0];
        
            if (($key == "DTSTART" || $key == "DTEND")) {
                
                if ($adeBase == 2024 || $adeBase == 2023) {                
                    $value = date('Ymd\THis', strtotime($value) - 2 * 3600);
                }
                else {
                    $isDaylightSaving = (bool)date('I', strtotime($value));
                    $value = date('Ymd\THis', strtotime($value) - ($isDaylightSaving ? 2 : 1) * 3600);
                }
                
            }
            $event_data[trim($key)] = trim($value);
        } else {
            if ($stop != 1) {
                $event_data[trim($tempKey)] .= '' . trim($line);
            }
        }
        if (strpos($lines, "(Exporté le:") !== false) {
            $stop = 1;
        }
    }

    return $event_data;
}
function get_data($response, $adeBase) {
    $list = [];
    $events = explode("BEGIN:VEVENT", $response);
    foreach ($events as $index => $value) {
        if ($index == 0) continue; // Skip the first split part if it's not an event
        $i = parse_event_data($value, $adeBase);
        $get_start_time_day = date('Y-m-d', strtotime($i['DTSTART']));
        
        $list[$get_start_time_day][] = $i;
    }
    return $list;
}


$adeBase = $_GET['adeBase'] ?? null;
$adeRessources = $_GET['adeRessources'] ?? null;
$lastUpdate = $_GET['lastUpdate'] ?? null;
$day = $_GET['date'] ?? null;

if ($adeBase === null || $adeRessources === null || $lastUpdate === null || $day === null) {
    http_response_code(400);
}

$folderPath = __DIR__ . "/db/{$adeBase}/{$adeRessources}";
if (!is_dir($folderPath)) {
    mkdir($folderPath, 0777, true);
}
if (!file_exists("{$folderPath}/file.json")) {
    file_put_contents("{$folderPath}/file.json", json_encode([]));
}
$date = DateTime::createFromFormat('Y-m-d', $day);

header('Content-Type: application/json');
if ($adeBase == 2024 ) {

    $file = file_get_contents("{$folderPath}/file.json");
    $data = json_decode($file, true);

    $ade_univ = "https://enpoche.normandie-univ.fr/aggrss/public/edt/edtProxy.php?edt_url=http://proxyade.unicaen.fr/ZimbraIcs/intervenant/$adeRessources.ics";
    $params = [];
    $response = file_get_contents($ade_univ);
    if (isset($http_response_header) && strpos($http_response_header[0], '200') === false) {
        error_log("Error: received non-200 response code");
    } else {
        if (strpos($response, "BEGIN:VEVENT") === false) {
            error_log("$adeBase:$adeRessources return anything");
        }
    }
    $response = get_data($response, $adeBase);
    for ($i = 0; $i < count($response); $i++) {
    if (isset($data[$date->format('Y-m-d')])) {
        if (isset($response[$date->format('Y-m-d')])) {
            $contentWithoutSequence = array_map(function($event) {
                unset($event['SEQUENCE']);
                unset($event['DTSTAMP']);
                unset($event['LAST-MODIFIED']);
                return $event;
            }, $data[$date->format('Y-m-d')]['content']);
        
            $responseWithoutSequence = array_map(function($event) {
                unset($event['SEQUENCE']);
                unset($event['DTSTAMP']);
                unset($event['LAST-MODIFIED']);
                return $event;
            }, $response[$date->format('Y-m-d')]);
        
            
            if (json_encode($contentWithoutSequence) !== json_encode($responseWithoutSequence)) {
                $data[$date->format('Y-m-d')]['content'] = $response[$date->format('Y-m-d')];
                $data[$date->format('Y-m-d')]['lastUpdate'] = round(microtime(true) * 1000);
            }
        }
        
    } 
        else{
            $data[$date->format('Y-m-d')]['content']  = isset($response[$date->format('Y-m-d')]) ? $response[$date->format('Y-m-d')] : [];
            $data[$date->format('Y-m-d')]['lastUpdate'] = round(microtime(true) * 1000);
        }
        $date->modify('+1 day');
    }
    file_put_contents("{$folderPath}/file.json", json_encode($data, JSON_UNESCAPED_UNICODE));
    


}
else if ($adeBase == 2023) {

    $file = file_get_contents("{$folderPath}/file.json");
    $data = json_decode($file, true);

    $ade_univ = "https://enpoche.normandie-univ.fr/aggrss/public/edt/edtProxy.php?edt_url=http://proxyade.unicaen.fr/ZimbraIcs/etudiant/$adeRessources.ics";
    $params = [];
    $response = file_get_contents($ade_univ);
    if (isset($http_response_header) && strpos($http_response_header[0], '200') === false) {
        error_log("Error: received non-200 response code");
    } else {
        if (strpos($response, "BEGIN:VEVENT") === false) {
            error_log("$adeBase:$adeRessources return anything");
        }
    }
    $response = get_data($response, $adeBase);
    for ($i = 0; $i < count($response); $i++) {
    if (isset($data[$date->format('Y-m-d')])) {
        if (isset($response[$date->format('Y-m-d')])) {
            $contentWithoutSequence = array_map(function($event) {
                unset($event['SEQUENCE']);
                unset($event['DTSTAMP']);
                unset($event['LAST-MODIFIED']);
                return $event;
            }, $data[$date->format('Y-m-d')]['content']);
        
            $responseWithoutSequence = array_map(function($event) {
                unset($event['SEQUENCE']);
                unset($event['DTSTAMP']);
                unset($event['LAST-MODIFIED']);
                return $event;
            }, $response[$date->format('Y-m-d')]);
        
            
            if (json_encode($contentWithoutSequence) !== json_encode($responseWithoutSequence)) {
                $data[$date->format('Y-m-d')]['content'] = $response[$date->format('Y-m-d')];
                $data[$date->format('Y-m-d')]['lastUpdate'] = round(microtime(true) * 1000);
            }
        }
        
    } 
        else{
            $data[$date->format('Y-m-d')]['content']  = isset($response[$date->format('Y-m-d')]) ? $response[$date->format('Y-m-d')] : [];
            $data[$date->format('Y-m-d')]['lastUpdate'] = round(microtime(true) * 1000);
        }
        $date->modify('+1 day');
    }
    file_put_contents("{$folderPath}/file.json", json_encode($data, JSON_UNESCAPED_UNICODE));
    


}
else {


    for ($i = 0; $i < 30; $i++) {
        $file = file_get_contents("{$folderPath}/file.json");
        $data = json_decode($file, true);
        $ade_univ = "http://ade.unicaen.fr/jsp/custom/modules/plannings/anonymous_cal.jsp";
        $params = [
            "resources" => strval($adeRessources),
            "projectId" => strval($adeBase),
            "firstDate" => $date->format('Y-m-d'),
            "lastDate" => $date->format('Y-m-d')
        ];
    
        $query = http_build_query($params);
        $request = $ade_univ . "?" . $query;
        $response = file_get_contents($request);
        if (isset($http_response_header) && strpos($http_response_header[0], '200') === false) {
            error_log("Error: received non-200 response code");
        } else {
            if (strpos($response, "Le projet est invalide") !== false || strpos($response, "BEGIN:VEVENT") === false) {
                error_log("$adeBase:$adeRessources return anything");
            }
        }
        $response = get_data($response, $adeBase);
        if (isset($data[$date->format('Y-m-d')])) {
            if (isset($response[$date->format('Y-m-d')])) {
                $contentWithoutSequence = array_map(function($event) {
                    unset($event['SEQUENCE']);
                    unset($event['DTSTAMP']);
                    unset($event['LAST-MODIFIED']);
                    return $event;
                }, $data[$date->format('Y-m-d')]['content']);
            
                $responseWithoutSequence = array_map(function($event) {
                    unset($event['SEQUENCE']);
                    unset($event['DTSTAMP']);
                    unset($event['LAST-MODIFIED']);
                    return $event;
                }, $response[$date->format('Y-m-d')]);
            
                
                if (json_encode($contentWithoutSequence) !== json_encode($responseWithoutSequence)) {
                    $data[$date->format('Y-m-d')]['content'] = $response[$date->format('Y-m-d')];
                    $data[$date->format('Y-m-d')]['lastUpdate'] = round(microtime(true) * 1000);
                }
            }
            
        } 
        else{
            $data[$date->format('Y-m-d')]['content']  = isset($response[$date->format('Y-m-d')]) ? $response[$date->format('Y-m-d')] : [];
            $data[$date->format('Y-m-d')]['lastUpdate'] = round(microtime(true) * 1000);
        }
        file_put_contents("{$folderPath}/file.json", json_encode($data, JSON_UNESCAPED_UNICODE));
        $date->modify('+1 day');
    }
}   
$date = DateTime::createFromFormat('Y-m-d', $day);
$result = [];
for ($i = 0; $i < 30; $i++) {
    $file = file_get_contents("{$folderPath}/file.json");
    $data = json_decode($file, true);
    if (isset($data[$date->format('Y-m-d')]) && $lastUpdate < $data[$date->format('Y-m-d')]['lastUpdate']) {
        usort($data[$date->format('Y-m-d')]['content'], function($a, $b) {
            return strtotime($a['DTSTART']) - strtotime($b['DTSTART']);
        });
        $result[$date->format('Y-m-d')] = $data[$date->format('Y-m-d')];
    }
    $date->modify('+1 day');
}
echo json_encode($result, JSON_UNESCAPED_UNICODE);

    