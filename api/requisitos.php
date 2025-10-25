<?php
require 'db_connection.php';
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
  // ---------- GET: leer requisitos ----------
  $id_usuario = isset($_GET['id_usuario']) ? (int)$_GET['id_usuario'] : 0;
  if ($id_usuario <= 0) { echo json_encode(['success'=>false,'msg'=>'id_usuario requerido']); exit; }

  $sql = "SELECT id_usuario, ciudad, direccion, ocupacion,
                 vivienda_propiedad, tipo_vivienda,
                 tiene_ninos, tiene_mascotas, espacio_exterior,
                 tiempo_libre, referencias, acepto_terminos,
                 created_at, updated_at
          FROM requisitos_adoptante
          WHERE id_usuario = ?";
  $st = $conn->prepare($sql);
  $st->bind_param('i', $id_usuario);
  $st->execute();
  $res = $st->get_result();
  $row = $res->fetch_assoc();

  echo json_encode(['success'=>true, 'data'=>$row ?: (object)[]], JSON_UNESCAPED_UNICODE);
  exit;
}

if ($method === 'POST') {
  // ---------- POST: guardar (upsert) ----------
  $raw = file_get_contents('php://input');
  $data = json_decode($raw, true);
  if (!is_array($data)) { echo json_encode(['success'=>false,'msg'=>'JSON inválido']); exit; }

  $id_usuario = isset($data['id_usuario']) ? (int)$data['id_usuario'] : 0;
  $ciudad     = isset($data['ciudad']) ? trim($data['ciudad']) : '';
  $direccion  = isset($data['direccion']) ? trim($data['direccion']) : '';
  $ocupacion  = isset($data['ocupacion']) ? trim($data['ocupacion']) : null;
  $v_prop     = isset($data['vivienda_propiedad']) ? trim($data['vivienda_propiedad']) : null;
  $t_viv      = isset($data['tipo_vivienda']) ? trim($data['tipo_vivienda']) : null;
  $t_ninos    = !empty($data['tiene_ninos']) ? 1 : 0;
  $t_masc     = !empty($data['tiene_mascotas']) ? 1 : 0;
  $esp_ext    = !empty($data['espacio_exterior']) ? 1 : 0;
  $t_libre    = isset($data['tiempo_libre']) ? trim($data['tiempo_libre']) : null;
  $refs       = isset($data['referencias']) ? trim($data['referencias']) : null;
  $acepto     = !empty($data['acepto_terminos']) ? 1 : 0;

  if ($id_usuario <= 0) { echo json_encode(['success'=>false,'msg'=>'id_usuario requerido']); exit; }
  if (!in_array($ciudad, ['Pasto','Ipiales'], true)) { echo json_encode(['success'=>false,'msg'=>'Ciudad inválida']); exit; }
  if ($direccion === '') { echo json_encode(['success'=>false,'msg'=>'Dirección requerida']); exit; }
  if (!$acepto) { echo json_encode(['success'=>false,'msg'=>'Debes aceptar términos']); exit; }

  $sql = "INSERT INTO requisitos_adoptante
          (id_usuario, ciudad, direccion, ocupacion, vivienda_propiedad, tipo_vivienda,
           tiene_ninos, tiene_mascotas, espacio_exterior, tiempo_libre, referencias, acepto_terminos)
          VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
          ON DUPLICATE KEY UPDATE
          ciudad=VALUES(ciudad),
          direccion=VALUES(direccion),
          ocupacion=VALUES(ocupacion),
          vivienda_propiedad=VALUES(vivienda_propiedad),
          tipo_vivienda=VALUES(tipo_vivienda),
          tiene_ninos=VALUES(tiene_ninos),
          tiene_mascotas=VALUES(tiene_mascotas),
          espacio_exterior=VALUES(espacio_exterior),
          tiempo_libre=VALUES(tiempo_libre),
          referencias=VALUES(referencias),
          acepto_terminos=VALUES(acepto_terminos)";

  $st = $conn->prepare($sql);
  // tipos: i s s s s s i i i s s i  -> "isssssiiissi"
  $st->bind_param(
    "isssssiiissi",
    $id_usuario, $ciudad, $direccion, $ocupacion, $v_prop, $t_viv,
    $t_ninos, $t_masc, $esp_ext, $t_libre, $refs, $acepto
  );
  $st->execute();

  echo json_encode(['success'=>true, 'msg'=>'Requisitos guardados'], JSON_UNESCAPED_UNICODE);
  exit;
}

http_response_code(405);
echo json_encode(['success'=>false,'msg'=>'Método no permitido']);
ini_set('display_errors', 0);
error_reporting(0);
