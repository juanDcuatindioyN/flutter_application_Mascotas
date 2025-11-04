# Despliegue de PHP en Railway con Docker

Este proyecto usa el servidor embebido de PHP dentro de un contenedor Docker.
Railway asigna un puerto en la variable de entorno `PORT`. El contenedor levanta
`php -S 0.0.0.0:$PORT -t /app` para servir archivos `.php` desde la raíz.

## Archivos incluidos
- `Dockerfile`: imagen basada en `php:8.2-cli` con `mysqli` y `pdo_mysql`.
- `.dockerignore`: evita subir archivos innecesarios al build context.

## Variables de entorno recomendadas en Railway
Configura estas variables en tu servicio (Railway → Variables):

- `DB_HOST`: host de MySQL (por ejemplo, `interchange.proxy.rlwy.net`)
- `DB_PORT`: puerto (por ejemplo, `41291`)
- `DB_NAME`: nombre de base de datos (por ejemplo, `railway`)
- `DB_USER`: usuario (por ejemplo, `root`)
- `DB_PASS`: contraseña

**Importante**: Actualiza tu `db_connection.php` para leer estas variables de entorno,
o reemplázalo por el archivo de ejemplo `db_connection.env.php` que adjuntamos aquí.

## Probar localmente (opcional)
```bash
docker build -t php-railway .
docker run --rm -p 8080:8080 -e PORT=8080 php-railway
```
Visita: http://localhost:8080/mascotas.php
(y el resto de endpoints, p. ej. `/usuario.php`, `/solicitudes.php`, `/autenticacion.php`).

## Despliegue en Railway
1. Sube estos archivos al repositorio **en la raíz** (junto con tus .php).
2. En Railway, crea un **Service** desde tu repo (detectará el Dockerfile).
3. Configura las variables de entorno listadas arriba.
4. Deploy. Luego, en **Networking**, genera un **Domain** público.
5. Prueba endpoints como: `https://TU-DOMINIO/mascotas.php?estado=disponible`

## db_connection con variables de entorno
Copia `db_connection.env.php` sobre tu `db_connection.php` (o adapta tu archivo)
para no dejar credenciales fijas en el código.
