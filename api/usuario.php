<?php
require 'db_connection.php';
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

$method = $_SERVER['REQUEST_METHOD'];
$action = isset($_GET['action']) ? trim($_GET['action']) : '';

if ($method === 'GET') {
  if ($action === 'profile') {
    // GET PROFILE
    $id = $_GET['id_usuario'] ?? '';

    if (!$id) {
      echo json_encode(['success' => false, 'msg' => 'Falta id_usuario']);
      exit;
    }

    $sql = "SELECT id_usuario, nombre, correo, telefono, calificacion
            FROM usuarios
            WHERE id_usuario = ?";
    $st = $conn->prepare($sql);
    $st->bind_param('i', $id);
    $st->execute();
    $res = $st->get_result();

    if ($row = $res->fetch_assoc()) {
      echo json_encode(['success' => true, 'data' => $row]);
    } else {
      echo json_encode(['success' => false, 'msg' => 'Usuario no encontrado']);
    }
  } elseif ($action === 'requisitos') {
    // GET REQUISITOS
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
  } else {
    echo json_encode(['success' => false, 'msg' => 'Acción GET no válida']);
  }
  exit;
}

if ($method === 'POST') {
  $raw = file_get_contents('php://input');
  $data = json_decode($raw, true);
  if (!is_array($data)) {
    echo json_encode(['success' => false, 'msg' => 'JSON inválido']); exit;
  }

  $action_post = isset($data['action']) ? trim($data['action']) : '';

  if ($action_post === 'update_profile') {
    // UPDATE PROFILE
    $id       = (int)($data['id_usuario'] ?? 0);
    $nombre   = trim($data['nombre']   ?? '');
    $correo   = trim($data['correo']   ?? '');
    $telefono = trim($data['telefono'] ?? '');

    if ($id <= 0 || $nombre === '' || $correo === '') {
      echo json_encode(['success' => false, 'msg' => 'Datos incompletos']); exit;
    }
    if (!filter_var($correo, FILTER_VALIDATE_EMAIL)) {
      echo json_encode(['success' => false, 'msg' => 'Correo inválido']); exit;
    }

    // (Opcional) Validar que el correo no esté usado por otro usuario
    $chk = $conn->prepare("SELECT id_usuario FROM usuarios WHERE correo = ? AND id_usuario <> ?");
    $chk->bind_param('si', $correo, $id);
    $chk->execute();
    $dup = $chk->get_result()->fetch_assoc();
    if ($dup) {
      echo json_encode(['success' => false, 'msg' => 'Ese correo ya está registrado']); exit;
    }

    $sql = "UPDATE usuarios SET nombre = ?, correo = ?, telefono = ? WHERE id_usuario = ?";
    $st = $conn->prepare($sql);
    $st->bind_param('sssi', $nombre, $correo, $telefono, $id);
    $ok = $st->execute();

    echo json_encode([
      'success' => (bool)$ok,
      'msg' => $ok ? 'Perfil actualizado correctamente' : 'Error al actualizar perfil'
    ]);
  } elseif ($action_post === 'change_password') {
    // CHANGE PASSWORD
    $id     = (int)($data['id_usuario'] ?? 0);
    $actual = trim($data['actual'] ?? '');
    $nueva  = trim($data['nueva'] ?? '');

    if ($id <= 0 || strlen($actual) < 6 || strlen($nueva) < 6) {
      echo json_encode(['success' => false, 'msg' => 'Datos inválidos']); exit;
    }

    // Buscar la contraseña actual
    $stmt = $conn->prepare("SELECT contrasena FROM usuarios WHERE id_usuario = ?");
    $stmt->bind_param("i", $id);
    $stmt->execute();
    $res = $stmt->get_result();
    $row = $res->fetch_assoc();

    if (!$row) {
      echo json_encode(['success' => false, 'msg' => 'Usuario no existe']); exit;
    }

    if (!password_verify($actual, $row['contrasena'])) {
      echo json_encode(['success' => false, 'msg' => 'Contraseña actual incorrecta']); exit;
    }

    // Actualizar contraseña
    $nuevaHash = password_hash($nueva, PASSWORD_BCRYPT);
    $update = $conn->prepare("UPDATE usuarios SET contrasena = ? WHERE id_usuario = ?");
    $update->bind_param("si", $nuevaHash, $id);
    $update->execute();

    echo json_encode(['success' => true, 'msg' => 'Contraseña actualizada']);
  } elseif ($action_post === 'save_requisitos') {
    // SAVE REQUISITOS
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
  } else {
    echo json_encode(['success' => false, 'msg' => 'Acción POST no válida']);
  }
  exit;
}

echo json_encode(['success' => false, 'msg' => 'Método no permitido']);
