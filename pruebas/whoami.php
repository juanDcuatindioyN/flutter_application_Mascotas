<?php
// htdocs/mascotas_api/whoami.php
header('Content-Type: application/json; charset=UTF-8');
echo json_encode([
  'file' => __FILE__,
  'time' => date('c'),
  'method' => $_SERVER['REQUEST_METHOD'],
  'content_type' => $_SERVER['CONTENT_TYPE'] ?? '',
  'get' => $_GET,
], JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
