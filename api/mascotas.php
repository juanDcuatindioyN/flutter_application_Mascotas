<?php
require 'db_connection.php';
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { http_response_code(200); exit; }

$estado = isset($_GET['estado']) ? $_GET['estado'] : 'disponible';

try {
  $sql = "SELECT id_mascota, nombre, especie, edad, estado_salud, foto, estado, id_fundacion
          FROM mascotas
          WHERE estado = ?
          ORDER BY id_mascota DESC";
  $st = $conn->prepare($sql);
  $st->bind_param("s", $estado);
  $st->execute();
  $res = $st->get_result();

  $items = [];
  while ($row = $res->fetch_assoc()) {
    $items[] = [
      "id_mascota"   => (int)$row["id_mascota"],
      "nombre"       => $row["nombre"],
      "especie"      => $row["especie"],
      "edad"         => isset($row["edad"]) ? (int)$row["edad"] : null,
      "estado_salud" => $row["estado_salud"],
      "foto"         => $row["foto"],
      "estado"       => $row["estado"],
      "id_fundacion" => $row["id_fundacion"] ? (int)$row["id_fundacion"] : null,
    ];
  }

  echo json_encode(["success" => true, "items" => $items]);
} catch (Throwable $e) {
  http_response_code(500);
  echo json_encode(["success" => false, "msg" => "Error: ".$e->getMessage()]);
}
