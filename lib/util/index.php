<?php
function parse_event_data($docstring) {
    $data = explode("\n", trim($docstring));
    $event_data = [];
    $tempKey = '';

    foreach ($data as $line) {
        $line = explode("(Exporté le:", $line)[0];
        if (strpos($line, ":") !== false) {
            list($key, $value) = explode(":", $line, 2);
            $tempKey = $key;
            $event_data[trim($key)] = trim($value);
        } else {
            $event_data[trim($tempKey)] .= '' . trim($line);
        }
    }

    return $event_data;
}
function get_data($response) {
    $events = explode("BEGIN:VEVENT", $response);
    foreach ($events as $index => $value) {
        if ($index == 0) continue; // Skip the first split part if it's not an event
        $i = parse_event_data($value);
        $get_start_time_day = date('Y-m-d', strtotime($i['DTSTART']));
        
        $list[$get_start_time_day][] = $i;
    }
    return $list;
}


$adeBase = $_GET['adeBase'] ?? null;
$adeRessources = $_GET['adeRessources'] ?? null;
$lastUpdate = $_GET['lastUpdate'] ?? null;
$day = $_GET['day'] ?? null;


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

for ($i = 0; $i < 15; $i++) {
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
    $response = get_data($response);
    echo json_encode($response);
    
    
    $query = http_build_query($params);
    $request = $ade_univ . "?" . $query;
    $response = file_get_contents($request);
    if (isset($http_response_header) && $http_response_header[0] != 'HTTP/1.1 200 ') {
        error_log("Error: received non-200 response code");
    } else {
        if (strpos($response, "Le projet est invalide") !== false || strpos($response, "BEGIN:VEVENT") === false) {
            error_log("$adeBase:$adeResources return anything");
        }
    }
    $response = get_data($response, $date->format('Y-m-d'));  
    echo json_encode($response);
}


header('Content-Type: application/json');
echo json_encode(['update' => true]);
?>


<!-- 
On get les paramètres de l'url
On vérifie si les paramètres sont null, si oui on renvoie une erreur 400
Si le fichier correspondant n'existe pas, on le telecharge

Si il y a une modification du fichier au moment de la verif on update le fichier et dans un fichier .txt on rajoute a la dernière ligne le UNIX timestamp
On limite a une requete pour les paramètres adeBase et adeRessources similaire une fois toute les 5 minutes max.
On renvoie true si le dernier timestamp est superieur a lastUpdate

Dans ce même fichier json on sauvegarde jour par jour les cours par exemple "28-08-2024" : [ { "debut" : "08:00", "fin" : "10:00", "nom" : "Maths", "prof" : "M. Dupont", "salle" : "A101" } ]


--> 