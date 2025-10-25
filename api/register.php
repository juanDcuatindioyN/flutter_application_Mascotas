<?php
require 'db_connection.php';
header("Content-Type: application/json; charset=UTF-8");

$in = json_decode(file_get_contents('php://input'), true);
if (!$in) { http_response_code(400); echo json_encode(["success"=>false,"msg"=>"JSON inválido"]); exit; }

$nombre    = trim($in['nombre'] ?? '');
$correo    = trim($in['correo'] ?? '');
$telefono  = trim($in['telefono'] ?? '');
$clave     = (string)($in['contrasena'] ?? '');

if ($nombre==='' || $correo==='' || $telefono==='' || $clave==='') {
  http_response_code(422); echo json_encode(["success"=>false,"msg"=>"Todos los campos son obligatorios"]); exit;
}
if (!preg_match('/^[^@]+@[^@]+\.[^@]+$/', $correo)) {
  http_response_code(422); echo json_encode(["success"=>false,"msg"=>"Correo inválido"]); exit;
}
if (!preg_match('/^3\d{9}$/', $telefono)) {
  http_response_code(422); echo json_encode(["success"=>false,"msg"=>"Teléfono inválido (Colombia)"]); exit;
}

try {
  $hash = password_hash($clave, PASSWORD_BCRYPT, ['cost' => 12]);
  $stmt = $conn->prepare("INSERT INTO usuarios (nombre, correo, contrasena, telefono, rol) VALUES (?,?,?,?, 'adoptante')");
  $stmt->bind_param("ssss", $nombre, $correo, $hash, $telefono);
  $stmt->execute();
  echo json_encode(["success"=>true, "id_usuario"=>$conn->insert_id]);
} catch (mysqli_sql_exception $e) {
  if ($e->getCode() == 1062) {
    http_response_code(409); echo json_encode(["success"=>false,"msg"=>"Correo ya registrado"]);
  } else {
    http_response_code(500); echo json_encode(["success"=>false,"msg"=>"Error: ".$e->getMessage()]);
  }
}
