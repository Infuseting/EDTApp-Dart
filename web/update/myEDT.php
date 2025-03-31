<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
$adeRessources = $_GET['adeRessources'] ?? null;
$adeBase = $_GET['adeBase'] ?? null;
if (!empty($adeRessources) && !empty($adeBase)) {	
    if ($adeBase == 2023) {
        $ade_univ = "https://enpoche.normandie-univ.fr/aggrss/public/edt/edtProxy.php?edt_url=http://proxyade.unicaen.fr/ZimbraIcs/etudiant/$adeRessources.ics";
        $response = file_get_contents($ade_univ);
        echo $response;
    }
    else if ($adeBase == 2024) {
        $ade_univ = "https://enpoche.normandie-univ.fr/aggrss/public/edt/edtProxy.php?edt_url=http://proxyade.unicaen.fr/ZimbraIcs/intervenant/$adeRessources.ics";
        $response = file_get_contents($ade_univ);
        echo $response;
    }
}
else {
    http_response_code(404);
    echo "Error 404: Resource not found.";
}