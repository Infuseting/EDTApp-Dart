<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
function getJsonFileMd5($filename) {
    // Ensure the file has a .json extension
    if (pathinfo($filename, PATHINFO_EXTENSION) !== 'json') {
        return false;
    }

    // Check if the file exists
    if (!file_exists($filename)) {
        return false;
    }

    // Get the file contents
    $fileContents = file_get_contents($filename);
    $fileContents = mb_convert_encoding($fileContents, 'UTF-8', 'auto');    // Return the MD5 hash of the file contents
    return md5($fileContents);
    
}

// Example usage
$fileName = $_GET['fileName'];
$md5Hash = getJsonFileMd5($fileName);
header('Content-Type: application/json');
echo json_encode(['hash' => $md5Hash !== false ? $md5Hash : null]);

?>