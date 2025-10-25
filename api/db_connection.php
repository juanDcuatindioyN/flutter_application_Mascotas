<?php
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

$host = "interchange.proxy.rlwy.net";
$port = 41291;
$user = "root";
$pass = "PKcvvnUTFlVzITtTCyOXAfvoelKhaPwS";
$db   = "railway";

$conn = new mysqli($host, $user, $pass, $db, $port);
if ($conn->connect_error) {
    die(json_encode(["success"=>false, "message"=>"DB error: ".$conn->connect_error]));
}
$conn->set_charset("utf8mb4");

$mysqli = new mysqli($host, $user, $pass, $db, $port);
if ($mysqli->connect_errno) {
  http_response_code(500);
  header('Content-Type: application/json; charset=UTF-8');
  echo json_encode(['success' => false, 'msg' => 'DB: ' . $mysqli->connect_error]);
  exit;
}
$mysqli->set_charset('utf8mb4');
?>

