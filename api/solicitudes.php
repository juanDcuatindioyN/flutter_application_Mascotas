<?php
require 'db_connection.php';
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

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
