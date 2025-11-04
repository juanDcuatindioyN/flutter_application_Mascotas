<?php
header('Content-Type: application/json; charset=UTF-8');
echo json_encode([
  'ok' => true,
  'service' => 'Mascotas API',
  'message' => 'Bienvenido al backend PHP desplegado en Railway',
  'endpoints' => [
    '/mascotas.php',
    '/usuario.php',
    '/solicitudes.php',
    '/autenticacion.php'
  ],
  'tip' => 'Visita /mascotas.php o /mascotas para probar la API'
], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
?>
