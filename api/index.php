<?php
header('Content-Type: application/json; charset=UTF-8');
echo json_encode([
  'ok' => true,
  'service' => 'Mascotas API',
  'endpoints' => [
    '/mascotas.php',
    '/usuario.php',
    '/solicitudes.php',
    '/autenticacion.php'
  ],
  'tip' => 'visita /mascotas.php para empezar'
], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
