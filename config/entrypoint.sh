#!/bin/sh

DOMAIN="TU_DOMINIO.duckdns.org"
EMAIL="email@example.com"
PASS="CONTRASENA_P12" # Puede ser cualquier contraseña, es para el .p12
LIVE="/etc/letsencrypt/live/$DOMAIN"
P12="$LIVE/keystore.p12"
CREDENTIALS="/opt/duckdns/duckdns.ini"

generate_p12() {
  echo "[certbot] Generando keystore.p12..."
  openssl pkcs12 -export \
    -in "$LIVE/fullchain.pem" \
    -inkey "$LIVE/privkey.pem" \
    -out "$P12" \
    -name spring \
    -password pass:$PASS

  if [ $? -eq 0 ]; then
    echo "[certbot] keystore.p12 generado correctamente."
  else
    echo "[certbot] ERROR al generar el keystore.p12"
  fi
}

ensure_p12() {
  if [ ! -f "$P12" ]; then
    echo "[certbot] keystore.p12 no encontrado. Generando..."
    generate_p12
  else
    echo "[certbot] keystore.p12 ya existe."
  fi
}

renew_all() {
  echo "[certbot] Renovando certificados..."
  certbot renew --dns-duckdns --dns-duckdns-credentials "$CREDENTIALS"
  generate_p12
}

# ---------- EJECUCIÓN INICIAL ----------

if [ ! -f "$LIVE/fullchain.pem" ]; then
  echo "[certbot] No existen certificados. Generando iniciales..."

  certbot certonly \
    --agree-tos \
    --no-eff-email \
    --email "$EMAIL" \
    --authenticator dns-duckdns \
    --dns-duckdns-credentials "$CREDENTIALS" \
    -d "$DOMAIN"

  if [ -f "$LIVE/fullchain.pem" ]; then
    generate_p12
  else
    echo "[certbot] ERROR: Certificados no generados."
  fi
else
  echo "[certbot] Certificados existentes detectados."
  ensure_p12
fi

# ---------- BUCLE INFINITO ----------
echo "[certbot] Iniciando bucle de renovación..."
while true; do
  sleep 43200   # 12 horas
  renew_all
done
