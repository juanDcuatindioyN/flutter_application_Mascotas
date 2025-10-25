<?php
require 'db_connection.php';

// Si llega aquí, la conexión no falló
$sql = "SELECT NOW() AS fecha, DATABASE() AS db, USER() AS usuario";
$result = $conn->query($sql);

if ($row = $result->fetch_assoc()) {
    echo json_encode([
        "success" => true,
        "project" => "mascotasJuan",
        "db"      => $row["db"],
        "usuario" => $row["usuario"],
        "fecha"   => $row["fecha"]
    ]);
} else {
    echo json_encode(["success" => false, "message" => "No se pudo ejecutar la consulta"]);
}
