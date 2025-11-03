<?php
require 'db_connection.php';
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  http_response_code(405);
  echo json_encode(['success'=>false, 'msg'=>'Método no permitido (usa POST)']);
  exit;
}

// Acepta JSON o form-data y normaliza nombres
$raw = file_get_contents('php://input');
$in  = json_decode($raw, true);
if (!is_array($in) || empty($in)) { $in = $_POST; }
$action = trim((string)($in['action'] ?? ''));

if ($action === 'login') {
  // LOGIN LOGIC
  $correo = trim((string)($in['correo'] ?? $in['email'] ?? ''));
  $clave  = (string)($in['contrasena'] ?? $in['password'] ?? $in['pass'] ?? '');

  if ($correo === '' || $clave === '') {
    http_response_code(422);
    echo json_encode(['success'=>false, 'msg'=>'Correo y contraseña son requeridos']);
    exit;
  }

  try {
    $stmt = $conn->prepare("SELECT id_usuario, nombre, correo, contrasena, rol, telefono FROM usuarios WHERE correo=? LIMIT 1");
    $stmt->bind_param("s", $correo);
    $stmt->execute();
    $res = $stmt->get_result();
    if (!$row = $res->fetch_assoc()) {
      http_response_code(404);
      echo json_encode(['success'=>false, 'msg'=>'Usuario no encontrado']);
      exit;
    }

    $stored = (string)($row['contrasena'] ?? '');
    $ok = false;
    $needsRehash = false;
    $path = 'none';

    // 1) Probar SIEMPRE como hash (bcrypt)
    if ($stored !== '') {
      $ok = @password_verify($clave, $stored);
      if ($ok) {
        $path = 'verify_hash';
        if (password_get_info($stored)['algo'] !== 0 &&
            password_needs_rehash($stored, PASSWORD_BCRYPT, ['cost'=>12])) {
          $needsRehash = true;
        }
      }
    }

    // 2) Fallback: almacenado en texto plano (migrar)
    if (!$ok && hash_equals($stored, $clave)) {
      $ok = true;
      $path = 'plaintext';
      $needsRehash = true;
    }

    if (!$ok) {
      http_response_code(401);
      echo json_encode(['success'=>false, 'msg'=>'Credenciales inválidas', 'why'=>['path'=>$path]]);
      exit;
    }

    if ($needsRehash) {
      $nuevo = password_hash($clave, PASSWORD_BCRYPT, ['cost'=>12]);
      $u = $conn->prepare("UPDATE usuarios SET contrasena=? WHERE id_usuario=?");
      $u->bind_param("si", $nuevo, $row['id_usuario']);
      $u->execute();
    }

    unset($row['contrasena']);
    echo json_encode(['success'=>true, 'user'=>$row, 'why'=>['path'=>$path, 'rehash'=>$needsRehash]]);
  } catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(['success'=>false, 'msg'=>'Error de servidor: '.$e->getMessage()]);
  }
} elseif ($action === 'register') {
  // REGISTER LOGIC
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
} else {
  http_response_code(400);
  echo json_encode(['success'=>false, 'msg'=>'Acción no válida']);
}
