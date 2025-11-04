# api/Dockerfile
FROM php:8.2-cli

RUN docker-php-ext-install mysqli pdo pdo_mysql

WORKDIR /app
# Como el contexto de build ES api/, copiamos el punto
COPY . /app

ENV PORT=8080
EXPOSE 8080

# Usa el router para URLs bonitas /mascotas, /usuario, etc.
CMD ["sh", "-c", "php -S 0.0.0.0:${PORT} -t /app /app/router.php"]
