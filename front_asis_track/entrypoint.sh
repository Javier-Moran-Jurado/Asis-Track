#!/bin/sh
set -e

# Genera env-config.js con las variables de entorno disponibles en runtime
cat <<EOF > /usr/share/nginx/html/env-config.js
window.env = {
  API_BASE_URL: "${API_BASE_URL:-http://localhost}"
};
EOF

echo "Generated env-config.js with API_BASE_URL=${API_BASE_URL:-http://localhost}"

# Arranca nginx en primer plano
exec nginx -g 'daemon off;'
