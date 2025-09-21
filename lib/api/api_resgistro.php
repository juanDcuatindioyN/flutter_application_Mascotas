<?php
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Recibir datos en formato JSON
$data = json_decode(file_get_contents("php://input"));

if (
    !empty($data->nombre) &&
    !empty($data->correo) &&
    !empty($data->contrasena) &&
    !empty($data->telefono)
) {
    $nombre = $data->nombre;
    $correo = $data->correo;
    $contrasena = password_hash($data->contrasena, PASSWORD_DEFAULT); 
    $telefono = $data->telefono;

    // Valores por defecto
    $rol = "adoptante";  
    $calificacion = 0;   
    $id_fundacion = null;

    // Conexión a MySQL
    $servername = "localhost";
    $username = "root";
    $password = "";
    $dbname = "mascotas";

    $conn = new mysqli($servername, $username, $password, $dbname);

    if ($conn->connect_error) {
        http_response_code(500);
        echo json_encode(["message" => "Error de conexión a la base de datos"]);
        exit();
    }

    // Verificar si el correo ya existe
    $checkEmail = $conn->prepare("SELECT id_usuario FROM usuarios WHERE correo = ?");
    $checkEmail->bind_param("s", $correo);
    $checkEmail->execute();
    $checkEmail->store_result();

    if ($checkEmail->num_rows > 0) {
        http_response_code(400);
        echo json_encode(["message" => "El correo ya está registrado"]);
        $checkEmail->close();
        $conn->close();
        exit();
    }
    $checkEmail->close();

    // Insertar nuevo usuario con valores por defecto
    $stmt = $conn->prepare("INSERT INTO usuarios (nombre, correo, contrasena, telefono, calificacion, rol, id_fundacion) 
                            VALUES (?, ?, ?, ?, ?, ?, ?)");
    $stmt->bind_param("ssssisi", $nombre, $correo, $contrasena, $telefono, $calificacion, $rol, $id_fundacion);

    if ($stmt->execute()) {
        http_response_code(201);
        echo json_encode([
            "message" => "Usuario registrado exitosamente",
            "id_usuario" => $stmt->insert_id
        ]);
    } else {
        http_response_code(500);
        echo json_encode(["message" => "Error al registrar usuario"]);
    }

    $stmt->close();
    $conn->close();
} else {
    http_response_code(400);
    echo json_encode(["message" => "Datos incompletos"]);
}
?>
