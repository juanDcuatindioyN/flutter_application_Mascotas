# Multi-stage build for Flutter web app

# Stage 1: Build the Flutter app
FROM cirrusci/flutter:3.19.6 AS build

WORKDIR /app

# Copy pubspec files first for better caching
COPY pubspec.* ./

# Get dependencies
RUN flutter pub get

# Copy the rest of the code
COPY . .

# Build the web app
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy built web app from build stage
COPY --from=build /app/build/web /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
