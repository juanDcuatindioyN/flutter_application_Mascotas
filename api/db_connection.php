<?php
// db_connection.env.php — versión que lee variables de entorno
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { 
    http_response_code(200); 
    exit; 
}

// Lee variables de entorno (con valores por defecto opcionales)
$host = getenv('DB_HOST') ?: 'mysql.railway.internal';
$port = getenv('DB_PORT') ?: 3306;
$user = getenv('DB_USER') ?: 'root';
$pass = getenv('DB_PASS') ?: 'PKcvvnUTFlVzITtTCyOXAfvoelKhaPwS';
$db   = getenv('DB_NAME') ?: 'railway';

// Conexión a MySQL
$conn = new mysqli($host, $user, $pass, $db, (int)$port);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "DB error: " . $conn->connect_error]);
    exit;
}

// Configurar charset
$conn->set_charset("utf8mb4");

// Compatibilidad con código que use $mysqli
$mysqli = $conn;
?>
