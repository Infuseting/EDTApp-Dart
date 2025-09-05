<?php 
$name = $_GET['name'] ?? '';
$surname = $_GET['surname'] ?? '';
$path = __DIR__ . '/prof.json';
if (!is_readable($path)) {
    header('HTTP/1.1 404 Not Found');
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['error' => 'prof.json not found']);
    exit;
}

$content = file_get_contents($path);
$data = json_decode($content, true);
if ($data === null) {
    header('HTTP/1.1 500 Internal Server Error');
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(['error' => 'Invalid JSON in prof.json']);
    exit;
}

$name = isset($name) ? trim($name) : '';
$surname = isset($surname) ? trim($surname) : '';
$results = [];
foreach($data['prof'] as $entry) {
    $descTT = strtolower($entry['descTT']);
    if (($name === '' || stripos($descTT, strtolower($name)) !== false) &&
        ($surname === '' || stripos($descTT, strtolower($surname)) !== false)) {
        $results[] = $entry;
    }
}

header('Content-Type: application/json; charset=utf-8');
echo json_encode($results, JSON_UNESCAPED_UNICODE);

?>