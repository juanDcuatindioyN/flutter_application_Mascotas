<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

require 'db_connection.php';

$raw = file_get_contents("php://input");
$data = json_decode($raw);

$nombre     = $data->nombre     ?? '';
$correo     = $data->correo     ?? '';
$contrasena = $data->contrasena ?? '';
$telefono   = $data->telefono   ?? '';

if (!$nombre || !$correo || !$contrasena) {
  http_response_code(400);
  echo json_encode(["success"=>false,"message"=>"nombre, correo y contraseña son obligatorios"]);
  exit;
}

if (!filter_var($correo, FILTER_VALIDATE_EMAIL)) {
  http_response_code(400);
  echo json_encode(["success"=>false,"message"=>"Correo inválido"]);
  exit;
}

$hash = password_hash($contrasena, PASSWORD_BCRYPT);
$rol  = 'adoptante'; 
try {
  $stmt = $conn->prepare(
    "INSERT INTO usuarios (nombre, correo, contrasena, telefono, rol) 
     VALUES (?,?,?,?,?)"
  );
  $stmt->bind_param("sssss", $nombre, $correo, $hash, $telefono, $rol);
  $stmt->execute();
  $id = $stmt->insert_id;
  $stmt->close();

  http_response_code(201);
  echo json_encode([
    "success"=>true,
    "message"=>"Registro exitoso",
    "user"=>[
      "id"=>$id,
      "nombre"=>$nombre,
      "correo"=>$correo,
      "telefono"=>$telefono,
      "rol"=>$rol
    ]
  ]);
} catch (mysqli_sql_exception $e) {
  if ($e->getCode() === 1062) { // correo duplicado
    http_response_code(409);
    echo json_encode(["success"=>false,"message"=>"El correo ya está registrado"]);
  } else {
    http_response_code(500);
    echo json_encode(["success"=>false,"message"=>"Error de servidor"]);
  }
}
$conn->close();
