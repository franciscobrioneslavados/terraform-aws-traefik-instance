#!/bin/bash
set -euo pipefail

LOG="/var/log/cloud-init-output.log"
exec > >(tee -a "$LOG") 2>&1

echo "===== Traefik Init Start $(date) ====="

#############################
# VARIABLES
#############################
ENVIRONMENT="${environment}"
DOMAIN_NAME="${domain_name}"
RESOLVER="${resolver}"
TRAEFIK_DASHBOARD_ENABLED="${traefik_dashboard_enabled}"

#############################
# METADATA
#############################
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
HOSTNAME=$(hostname)

echo "Instance: $INSTANCE_ID"
echo "Public IP: $PUBLIC_IP"
echo "Private IP: $PRIVATE_IP"

#############################
# ACTUALIZAR SISTEMA
#############################
echo "Updating system..."
apt-get update -y
apt-get upgrade -y
apt-get install -y curl wget jq unzip docker.io docker-compose

#############################
# DOCKER
#############################
echo "Configuring Docker..."
systemctl enable docker
usermod -aG docker ubuntu
systemctl start docker

#############################
# DIRECTORIOS
#############################
mkdir -p /opt/traefik/{config,letsencrypt,logs}

#############################
# TRAEFIK CONFIG - STATIC
#############################
cat > /opt/traefik/traefik.yml <<EOF
api:
  dashboard: $TRAEFIK_DASHBOARD_ENABLED
  insecure: $TRAEFIK_DASHBOARD_ENABLED

entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

log:
  level: INFO
  filePath: "/logs/traefik.log"

accessLog:
  filePath: "/logs/access.log"

providers:
  docker:
    endpoint: "unix:///var/run/docker.sock"
    exposedByDefault: false
    network: traefik-public
  file:
    directory: /config
    watch: true
EOF

#############################
# MIDDLEWARES
#############################
cat > /opt/traefik/config/middlewares.yml <<'EOF'
http:
  middlewares:
    security-headers:
      headers:
        frameDeny: true
        contentTypeNosniff: true
        browserXssFilter: true
        sslRedirect: true
        stsSeconds: 31536000
        stsIncludeSubdomains: true
        stsPreload: true
EOF

#############################
# HTTP CATCHALL (serve index.html)
#############################
cat > /opt/traefik/config/http-catchall.yml <<'EOF'
http:
  routers:
    http-catchall:
      rule: "PathPrefix(`/`)"
      entryPoints:
        - web
      service: static-svc
  services:
    static-svc:
      loadBalancer:
        servers:
          - url: "http://127.0.0.1:8000"
EOF

#############################
# SIMPLE HTTP SERVER PARA INDEX
#############################
cat > /opt/traefik/run.sh <<'EOF'
#!/bin/bash
cd /var/www/html 2>/dev/null || mkdir -p /var/www/html && cd /var/www/html
echo "Serving static files on :8000"
while true; do
  python3 -m http.server 8000 2>/dev/null || nc -l -p 8000 < /var/www/html/index.html
  sleep 1
done
EOF
chmod +x /opt/traefik/run.sh

mkdir -p /var/www/html

cat > /var/www/html/index.html <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Traefik Proxy - Actividad 4</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .container {
            background: white;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            text-align: center;
            max-width: 500px;
        }
        h1 { color: #667eea; margin-bottom: 20px; }
        p { color: #666; margin: 10px 0; }
        .ip { font-size: 2em; color: #333; font-weight: bold; }
        .status { color: #10b981; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Traefik Proxy is Running!</h1>
        <p>Instance: $INSTANCE_ID</p>
        <p>Public IP:</p>
        <p class="ip">$PUBLIC_IP</p>
        <p class="status">Status: Active</p>
        <p>Add Docker services with Traefik labels</p>
    </div>
</body>
</html>
EOF

nohup /opt/traefik/run.sh >/dev/null 2>&1 &

#############################
# DOCKER COMPOSE
#############################
DASHBOARD_PORT=""
if [ "$TRAEFIK_DASHBOARD_ENABLED" = "true" ]; then
    DASHBOARD_PORT="- \"8080:8080\""
fi

cat > /opt/traefik/docker-compose.yml <<EOF
version: "3.8"

services:
  traefik:
    image: traefik:v3.0
    container_name: traefik
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    networks:
      - traefik-public
    ports:
      - "80:80"
      - "443:443"
      $DASHBOARD_PORT
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /opt/traefik/traefik.yml:/traefik.yml:ro
      - /opt/traefik/letsencrypt:/letsencrypt
      - /opt/traefik/logs:/logs
      - /opt/traefik/config:/config:ro
    labels:
      - "traefik.enable=true"

networks:
  traefik-public:
    external: true
EOF

#############################
# RED DOCKER
#############################
echo "Creating Docker network..."
docker network create traefik-public 2>/dev/null || true

#############################
# PERMISOS
#############################
chown -R root:root /opt/traefik
chmod 600 /opt/traefik/letsencrypt 2>/dev/null || mkdir -p /opt/traefik/letsencrypt && chmod 600 /opt/traefik/letsencrypt
chmod +x /opt/traefik/docker-compose.yml

#############################
# INICIAR TRAEFIK
#############################
echo "Starting Traefik..."
cd /opt/traefik
docker-compose up -d

#############################
# VERIFICAR
#############################
sleep 5
docker ps | grep traefik

echo "===== Traefik Init Complete ====="
echo "Public IP: $PUBLIC_IP"
echo "HTTP: http://$PUBLIC_IP"
echo "HTTPS: https://$PUBLIC_IP"
if [ "$TRAEFIK_DASHBOARD_ENABLED" = "true" ]; then
    echo "Dashboard: http://$PUBLIC_IP:8080"
fi
