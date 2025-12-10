#!/bin/sh
# VARIABLES GLOBALES PARA EL USO DEL ENTRYPOINT
DOMAIN="TU_DOMINIO.duckdns.org" # Dominio generado en duckDNS
PASS="123456" # Contraseña para el .p12
LIVE="/etc/letsencrypt/live/$DOMAIN" # Ruta donde se generarán los certificados
CREDENTIALS="/opt/duckdns/duckdns.ini" # Token de duckDNS

# Cada vez que arranca, intenta renovar
renew_all() {
    echo "[certbot] Renovando certificados..."
    certbot renew --dns-duckdns --dns-duckdns-credentials "$CREDENTIALS"

    # Si existe fullchain.pem entonces convertimos a .p12
    if [ -f "$LIVE/fullchain.pem" ] && [ -f "$LIVE/privkey.pem" ]; then
        echo "[certbot] Generando keystore.p12..."
        openssl pkcs12 -export \
            -in "$LIVE/fullchain.pem" \
            -inkey "$LIVE/privkey.pem" \
            -out "$LIVE/keystore.p12" \
            -name spring \
            -password pass:$PASS
    fi
}

# --- EJECUCIÓN INICIAL ---
# Si NO existen certificados, los generamos por primera vez
if [ ! -f "$LIVE/fullchain.pem" ]; then
    echo "[certbot] No existen certificados. Generando iniciales..."
    certbot certonly \
        --agree-tos \
        --no-eff-email \
        --email correo@example.com \
        --dns-duckdns \
        --dns-duckdns-credentials "$CREDENTIALS" \
        -d "$DOMAIN"

    renew_all
fi

echo "[certbot] Certificados listos. Iniciando bucle de renovación..."

# --- BUCLE INFINITO ---
# Cada 12 horas ejecuta renovación + regeneración del .p12
while true; do
    sleep 43200   # 12h = 43200 segundos
    renew_all
done
