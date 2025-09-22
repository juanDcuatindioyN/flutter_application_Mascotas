<?php
header("Content-Type: application/json; charset=UTF-8");

$host = '127.0.0.1';
$port = 3306;
$name = 'mascotas';
$user = 'root';
$pass = ''; // XAMPP por defecto

$conn = new mysqli($host, $user, $pass, $name, $port);
if ($conn->connect_error) {
  http_response_code(500);
  echo json_encode(["success"=>false,"message"=>"Error de conexión: ".$conn->connect_error]);
  exit;
}
$conn->set_charset("utf8mb4");
