# Dockerfile — PHP API con router para Railway
FROM php:8.2-cli

# Instalar extensiones necesarias
RUN docker-php-ext-install mysqli pdo pdo_mysql

# Directorio de trabajo
WORKDIR /app

# Copiar archivos desde api/ si el Dockerfile está en la raíz
COPY api/ /app

# Puerto de Railway
ENV PORT=8080
EXPOSE 8080

# Servidor PHP con router
CMD ["sh", "-c", "php -S 0.0.0.0:${PORT} -t /app /app/router.php"]
