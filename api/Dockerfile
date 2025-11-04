# Dockerfile — PHP API simple para Railway (servidor embebido)
FROM php:8.2-cli

# Extensiones necesarias (ajusta si tu app requiere otras: gd, intl, zip, etc.)
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Directorio de trabajo
WORKDIR /app

# Copiamos el código
COPY . /app

# Puerto dinámico que asigna Railway
ENV PORT=8080

# (Opcional) Expose informativo
EXPOSE 8080

# Arranque del servidor embebido de PHP escuchando en 0.0.0.0:$PORT
# -t /app usa la raíz como "document root" (porque tus endpoints están en /app/*.php)
CMD ["sh", "-c", "php -S 0.0.0.0:${PORT} -t /app /app/router.php"]
