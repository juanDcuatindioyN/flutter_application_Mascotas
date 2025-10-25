<?php
require 'db_connection.php'; // Debe crear $mysqli = new mysqli(...)

header('Content-Type: application/json; charset=UTF-8');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
  http_response_code(204);
  exit;
}

// Helper de salida JSON
function out_json($ok, $msg = '', $extra = []) {
  echo json_encode(array_merge(['success' => $ok, 'msg' => $msg], $extra));
  exit;
}

// Lee id_solicitud (POST JSON o GET)
$idSolicitud = 0;
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $raw = file_get_contents('php://input');
  if (!empty($raw)) {
    $j = json_decode($raw, true);
    if (json_last_error() === JSON_ERROR_NONE && isset($j['id_solicitud'])) {
      $idSolicitud = (int)$j['id_solicitud'];
    }
  }
}
if (!$idSolicitud && isset($_GET['id_solicitud'])) {
  $idSolicitud = (int)$_GET['id_solicitud'];
}

if (!$idSolicitud) {
  out_json(false, 'Falta id_solicitud');
}

// Usa la conexión que crea db_connection.php
if (!isset($mysqli) || !$mysqli) {
  out_json(false, 'Sin conexión a la base de datos');
}

// Cambia a estado cancelada
$stmt = $mysqli->prepare("UPDATE solicitudes SET estado = 'cancelada' WHERE id_solicitud = ?");
if (!$stmt) {
  out_json(false, 'SQL: ' . $mysqli->error);
}
$stmt->bind_param('i', $idSolicitud);
if (!$stmt->execute()) {
  out_json(false, 'SQL: ' . $stmt->error);
}

if ($stmt->affected_rows === 0) {
  out_json(false, 'No encontrada o ya cancelada');
}

out_json(true, 'Solicitud cancelada', ['id_solicitud' => $idSolicitud]);
