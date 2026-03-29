# Traefik Proxy - EC2

Reverse proxy y balanceador de carga con **Traefik v3** desplegado en EC2.

## Sin Cloudflare ni Dominio (Modo IP Directa)

Por defecto funciona con **IP pública** y certificado **self-signed**. Perfecto para pruebas.

## Con Cloudflare y Dominio (Modo SSL)

Opcionalmente puedes agregar dominio y SSL con Let's Encrypt.

## Arquitectura

```
# Modo IP Directa
Internet → Traefik (EC2) → Contenedores Docker

# Modo con Dominio
Internet → Traefik (EC2) → Contenedores Docker
```

## Configuración Rápida (Sin Dominio)

1. Copia y edita las variables:
   ```bash
   cp develop.tfvars.example develop.tfvars
   ```

2. Edita `develop.tfvars`:
   ```hcl
   aws_region  = "us-east-1"
   vpc_id      = "vpc-xxxxxxxx"
   public_subnet_ids = ["subnet-xxxxxxxx"]
   
   project_name = "traefik-proxy"
   environment = "development"
   owner_name  = "Tu Nombre"
   
   ssh_allowed_cidr = ["tu-ip/32"]
   
   # Dejar vacio para modo IP directa
   domain_name          = ""
   cloudflare_api_token = ""
   cloudflare_zone_id   = ""
   ```

3. Aplica:
   ```bash
   terraform init
   terraform apply -var-file="develop.tfvars"
   ```

## Configuración con Dominio y SSL

```hcl
domain_name          = "tudominio.com"
cloudflare_api_token = "tu-cloudflare-token"
cloudflare_zone_id   = "tu-zone-id"
```

## Agregar Servicios

Usa **labels Docker** en tu `docker-compose.yml`:

```yaml
services:
  mi-app:
    image: mi-app:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.miapp.rule=PathPrefix(`/miapp`)"
      - "traefik.http.services.miapp.loadbalancer.server.port=3000"
    networks:
      - traefik-public

networks:
  traefik-public:
    external: true
```

## Endpoints Después del Deploy

| Servicio | URL |
|----------|-----|
| HTTP | `http://<IP-PUBLICA>` |
| Dashboard | `http://<IP-PUBLICA>:8080` (si habilitado) |

## Comandos Útiles

```bash
# SSH a la instancia
ssh -i mi-key.pem ubuntu@<IP-PUBLICA>

# Ver estado de Traefik
docker ps | grep traefik

# Ver logs
docker logs traefik -f

# Ver contenedores descubiertos
curl http://localhost:8080/api/http/routers

# Reiniciar
cd /opt/traefik && docker-compose restart
```

## Estructura del Proyecto

```
├── main.tf                    # Recursos AWS
├── variables.tf               # Variables
├── outputs.tf                # Outputs
├── provider.tf               # Providers
├── templates/
│   └── user-data-traefik.sh # Script de init
├── develop.tfvars.example
└── README.md
```

## Recursos Creados

| Recurso | Descripción |
|---------|-------------|
| EC2 Instance | Ubuntu 22.04, t3.micro |
| Security Group | HTTP, HTTPS, SSH, Dashboard |
| Elastic IP | IP pública fija |
| Key Pair | SSH automático |

## Costos

- **EC2 t3.micro**: ~$8.50/mes (o gratis con free tier)
- **EIP**: ~$3.60/mes (si no usa free tier)
