<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header("Content-Type: application/json; charset=UTF-8");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(204); exit; }

$DEBUG = isset($_GET['debug']);
if ($DEBUG) { $trace = []; $trace[] = "start"; }

ini_set('display_errors', '0');
ini_set('log_errors', '1');
ini_set('error_log', __DIR__ . '/php_errors.log');

require __DIR__ . '/db_connection.php';
if ($DEBUG) { $trace[] = "db_ok"; }

$raw = file_get_contents("php://input");
if ($DEBUG) { $trace[] = "raw=" . ($raw === '' ? '(empty)' : $raw); }

$data = json_decode($raw);
if (!is_object($data)) {
  http_response_code(400);
  echo json_encode(["success"=>false,"message"=>"JSON inválido o vacío","raw"=>$raw, "debug"=>$DEBUG?$trace:null]);
  exit;
}

$correo     = $data->correo     ?? '';
$contrasena = $data->contrasena ?? '';
if (!$correo || !$contrasena) {
  http_response_code(400);
  echo json_encode(["success"=>false,"message"=>"correo y contraseña son obligatorios","debug"=>$DEBUG?$trace:null]);
  exit;
}

try {
  if ($DEBUG) { $trace[] = "query_user"; }
  $stmt = $conn->prepare("SELECT id_usuario, nombre, correo, contrasena, telefono, rol, id_fundacion
                          FROM usuarios WHERE correo = ?");
  $stmt->bind_param("s", $correo);
  $stmt->execute();
  $res  = $stmt->get_result();
  $user = $res->fetch_assoc();
  $stmt->close();

  if ($DEBUG) { $trace[] = "user_found=" . ($user ? 'yes' : 'no'); }

  if (!$user || !password_verify($contrasena, $user['contrasena'])) {
    http_response_code(401);
    echo json_encode(["success"=>false,"message"=>"Credenciales inválidas","debug"=>$DEBUG?$trace:null]);
    $conn->close(); exit;
  }

  http_response_code(200);
  echo json_encode([
    "success"=>true,
    "message"=>"Login exitoso",
    "user"=>[
      "id"           => (int)$user['id_usuario'],
      "nombre"       => $user['nombre'],
      "correo"       => $user['correo'],
      "telefono"     => $user['telefono'],
      "rol"          => $user['rol'],
      "id_fundacion" => $user['id_fundacion'] ? (int)$user['id_fundacion'] : null
    ],
    "debug"=>$DEBUG?$trace:null
  ]);
} catch (Throwable $e) {
  error_log("login.php error: ".$e->getMessage());
  http_response_code(500);
  echo json_encode(["success"=>false,"message"=>"Error de servidor", "debug"=>$DEBUG?$trace:null]);
}
$conn->close();
