# ── Etapa 1: Build Flutter Web ──
FROM ghcr.io/cirruslabs/flutter:stable AS builder

WORKDIR /app
COPY . .
RUN flutter build web --release

# ── Etapa 2: Nginx con env-config.js dinámico ──
FROM nginx:alpine

# Copiar build estático de Flutter
COPY --from=builder /app/build/web /usr/share/nginx/html

# Copiar configuración de nginx para servir estáticos
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Entrypoint que genera env-config.js y arranca nginx
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
