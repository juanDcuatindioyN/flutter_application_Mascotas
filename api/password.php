<?php
require 'db_connection.php';

error_reporting(0);
ini_set('display_errors', 0);

header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  http_response_code(200);
  exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
  if (function_exists('ob_get_length') && ob_get_length()) ob_clean();
  http_response_code(405);
  echo json_encode(['success' => false, 'msg' => 'Método no permitido']);
  exit;
}

$raw = file_get_contents('php://input');
$data = json_decode($raw, true);

if (!is_array($data)) {
  if (function_exists('ob_get_length') && ob_get_length()) ob_clean();
  echo json_encode(['success' => false, 'msg' => 'JSON inválido']);
  exit;
}

$id     = (int)($data['id_usuario'] ?? 0);
$actual = trim($data['actual'] ?? '');
$nueva  = trim($data['nueva'] ?? '');

if ($id <= 0 || strlen($actual) < 6 || strlen($nueva) < 6) {
  if (function_exists('ob_get_length') && ob_get_length()) ob_clean();
  echo json_encode(['success' => false, 'msg' => 'Datos inválidos']);
  exit;
}

// Buscar la contraseña actual
$stmt = $conn->prepare("SELECT contrasena FROM usuarios WHERE id_usuario = ?");
$stmt->bind_param("i", $id);
$stmt->execute();
$res = $stmt->get_result();
$row = $res->fetch_assoc();

if (!$row) {
  if (function_exists('ob_get_length') && ob_get_length()) ob_clean();
  echo json_encode(['success' => false, 'msg' => 'Usuario no existe']);
  exit;
}

if (!password_verify($actual, $row['contrasena'])) {
  if (function_exists('ob_get_length') && ob_get_length()) ob_clean();
  echo json_encode(['success' => false, 'msg' => 'Contraseña actual incorrecta']);
  exit;
}

// Actualizar contraseña
$nuevaHash = password_hash($nueva, PASSWORD_BCRYPT);
$update = $conn->prepare("UPDATE usuarios SET contrasena = ? WHERE id_usuario = ?");
$update->bind_param("si", $nuevaHash, $id);
$update->execute();

if (function_exists('ob_get_length') && ob_get_length()) ob_clean();
echo json_encode(['success' => true, 'msg' => 'Contraseña actualizada']);
