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

$in = json_decode(file_get_contents('php://input'), true);
if (!is_array($in) || empty($in)) { $in = $_POST; }

$id_usuario = intval($in['id_usuario'] ?? 0);
$id_mascota = intval($in['id_mascota'] ?? 0);
if ($id_usuario <= 0 || $id_mascota <= 0) {
  http_response_code(422);
  echo json_encode(['success'=>false, 'msg'=>'id_usuario y id_mascota son requeridos']);
  exit;
}

try {
  // Verificar existencia de usuario y mascota (opcional pero recomendado)
  $chk = $conn->prepare("SELECT 1 FROM usuarios WHERE id_usuario=?");
  $chk->bind_param("i", $id_usuario);
  $chk->execute();
  if (!$chk->get_result()->fetch_row()) {
    http_response_code(404);
    echo json_encode(['success'=>false, 'msg'=>'Usuario no existe']);
    exit;
  }
  $chk = $conn->prepare("SELECT 1 FROM mascotas WHERE id_mascota=?");
  $chk->bind_param("i", $id_mascota);
  $chk->execute();
  if (!$chk->get_result()->fetch_row()) {
    http_response_code(404);
    echo json_encode(['success'=>false, 'msg'=>'Mascota no existe']);
    exit;
  }

  // Evitar duplicados en estado pendiente
  $dup = $conn->prepare("SELECT id_solicitud FROM solicitudes WHERE id_usuario=? AND id_mascota=? AND estado='pendiente' LIMIT 1");
  $dup->bind_param("ii", $id_usuario, $id_mascota);
  $dup->execute();
  if ($dup->get_result()->fetch_assoc()) {
    http_response_code(409);
    echo json_encode(['success'=>false, 'msg'=>'Ya tienes una solicitud pendiente para esta mascota']);
    exit;
  }

  // Insertar solicitud
  $ins = $conn->prepare("INSERT INTO solicitudes (id_usuario, id_mascota, estado) VALUES (?,?, 'pendiente')");
  $ins->bind_param("ii", $id_usuario, $id_mascota);
  $ins->execute();

  echo json_encode(['success'=>true, 'id_solicitud'=>$conn->insert_id, 'msg'=>'Solicitud enviada']);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(['success'=>false, 'msg'=>'Error de servidor: '.$e->getMessage()]);
}
