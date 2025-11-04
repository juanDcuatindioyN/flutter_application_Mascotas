<?php
// Si el archivo físico existe (css, js, imágenes, .php), que lo sirva tal cual
$requested = __DIR__ . parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
if (is_file($requested)) {
  return false;
}

// Rutas simples de ejemplo:
$path = trim(parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH), '/');

switch ($path) {
  case '':
    require __DIR__ . '/index.php'; // bienvenida
    break;

  case 'mascotas':
    require __DIR__ . '/mascotas.php';
    break;

  case 'usuario':
    require __DIR__ . '/usuario.php';
    break;

  case 'solicitudes':
    require __DIR__ . '/solicitudes.php';
    break;

  case 'autenticacion':
    require __DIR__ . '/autenticacion.php';
    break;

  default:
    http_response_code(404);
    header('Content-Type: application/json; charset=UTF-8');
    echo json_encode(['ok'=>false,'error'=>'Ruta no encontrada','path'=>$path], JSON_UNESCAPED_UNICODE);
}
