<?php
require 'db_connection.php';
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
  // LIST REQUESTS
  $id_usuario = isset($_GET['id_usuario']) ? intval($_GET['id_usuario']) : 0;
  if ($id_usuario <= 0) {
    http_response_code(400);
    echo json_encode(["success"=>false,"msg"=>"id_usuario requerido"]);
    exit;
  }

  try {
    // Puedes añadir fecha en la tabla solicitudes si quieres (ej: created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)
    // Aquí traemos datos básicos de la mascota
    $sql = "SELECT s.id_solicitud, s.estado,
                   m.id_mascota, m.nombre AS mascota_nombre, m.especie, m.foto,
                   f.nombre AS fundacion_nombre
            FROM solicitudes s
            JOIN mascotas m ON s.id_mascota = m.id_mascota
            LEFT JOIN fundaciones f ON m.id_fundacion = f.id_fundacion
            WHERE s.id_usuario = ?
            ORDER BY s.id_solicitud DESC";
    $st = $conn->prepare($sql);
    $st->bind_param("i", $id_usuario);
    $st->execute();
    $res = $st->get_result();
    $items = [];
    while ($row = $res->fetch_assoc()) {
      $items[] = [
        "id_solicitud" => (int)$row["id_solicitud"],
        "estado" => $row["estado"],
        "mascota" => [
          "id" => (int)$row["id_mascota"],
          "nombre" => $row["mascota_nombre"],
          "especie" => $row["especie"],
          "foto" => $row["foto"],
          "fundacion" => $row["fundacion_nombre"],
        ],
      ];
    }
    echo json_encode(["success"=>true, "items"=>$items]);
  } catch (Throwable $e) {
    http_response_code(500);
    echo json_encode(["success"=>false,"msg"=>"Error: ".$e->getMessage()]);
  }
} elseif ($method === 'POST') {
  $raw = file_get_contents('php://input');
  $data = json_decode($raw, true);
  if (!is_array($data)) { $data = $_POST; }

  $action = isset($data['action']) ? trim($data['action']) : '';

  if ($action === 'create') {
    // CREATE REQUEST
    $id_usuario = intval($data['id_usuario'] ?? 0);
    $id_mascota = intval($data['id_mascota'] ?? 0);
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
  } elseif ($action === 'cancel') {
    // CANCEL REQUEST
    $idSolicitud = (int)($data['id_solicitud'] ?? 0);

    if (!$idSolicitud) {
      echo json_encode(['success' => false, 'msg' => 'Falta id_solicitud']);
      exit;
    }

    // Usa la conexión que crea db_connection.php
    if (!isset($mysqli) || !$mysqli) {
      echo json_encode(['success' => false, 'msg' => 'Sin conexión a la base de datos']);
      exit;
    }

    // Cambia a estado cancelada
    $stmt = $mysqli->prepare("UPDATE solicitudes SET estado = 'cancelada' WHERE id_solicitud = ?");
    if (!$stmt) {
      echo json_encode(['success' => false, 'msg' => 'SQL: ' . $mysqli->error]);
      exit;
    }
    $stmt->bind_param('i', $idSolicitud);
    if (!$stmt->execute()) {
      echo json_encode(['success' => false, 'msg' => 'SQL: ' . $stmt->error]);
      exit;
    }

    if ($stmt->affected_rows === 0) {
      echo json_encode(['success' => false, 'msg' => 'No encontrada o ya cancelada']);
      exit;
    }

    echo json_encode(['success' => true, 'msg' => 'Solicitud cancelada', 'id_solicitud' => $idSolicitud]);
  } else {
    http_response_code(400);
    echo json_encode(['success' => false, 'msg' => 'Acción no válida']);
  }
} else {
  http_response_code(405);
  echo json_encode(['success' => false, 'msg' => 'Método no permitido']);
}
