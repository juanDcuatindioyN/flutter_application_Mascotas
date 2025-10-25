<?php
require 'db_connection.php';
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') { 
    http_response_code(200); 
    exit; 
}

// ---------- GET: obtener perfil ----------
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $id = $_GET['id_usuario'] ?? '';

    if (!$id) {
        echo json_encode(['success' => false, 'msg' => 'Falta id_usuario']);
        exit;
    }

    $sql = "SELECT id_usuario, nombre, correo, telefono 
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
    exit;
}

// ---------- POST: actualizar perfil ----------
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $data = json_decode(file_get_contents("php://input"), true);
    if (!$data) {
        echo json_encode(['success' => false, 'msg' => 'JSON inválido']); exit;
    }

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
    exit;
}


echo json_encode(['success' => false, 'msg' => 'Método no permitido']);
