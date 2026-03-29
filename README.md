# Terraform AWS EC2 Traefik Proxy Module

Módulo de Terraform para desplegar un proxy reverso **Traefik v3** en una instancia EC2.

## Usar como Módulo

```hcl
module "traefik_proxy" {
  source = "github.com/tu-org/terraform-aws-ec2-traefik-proxy"

  aws_region        = "us-east-1"
  vpc_id            = "vpc-xxxxxxxx"
  public_subnet_ids = ["subnet-xxxxxxxx"]

  project_name  = "traefik-proxy"
  environment   = "production"
  owner_name    = "Team"

  ssh_allowed_cidr = ["tu-ip/32"]
}
```

## Inputs

| Variable | Tipo | Default | Descripción |
|----------|------|---------|-------------|
| `aws_region` | string | - | Región AWS |
| `vpc_id` | string | - | ID de la VPC |
| `public_subnet_ids` | list(string) | - | IDs de subnets públicas |
| `project_name` | string | `"traefik-proxy"` | Nombre del proyecto |
| `environment` | string | `"development"` | Entorno |
| `owner_name` | string | - | Dueño del recurso |
| `traefik_instance_type` | string | `"t3.micro"` | Tipo de instancia EC2 |
| `ssh_allowed_cidr` | list(string) | - | CIDRs permitidos para SSH |
| `domain_name` | string | `""` | Dominio (opcional) |
| `cloudflare_api_token` | string | `""` | Token Cloudflare (opcional) |
| `cloudflare_zone_id` | string | `""` | Zone ID Cloudflare (opcional) |
| `traefik_dashboard_enabled` | bool | `false` | Habilitar dashboard |
| `traefik_dashboard_users` | string | `""` | Users dashboard (htpasswd) |

## Outputs

| Output | Descripción |
|--------|-------------|
| `traefik_public_ip` | IP pública del servidor |
| `traefik_public_dns` | DNS público del servidor |
| `traefik_instance_id` | ID de la instancia EC2 |
| `traefik_security_group_id` | ID del Security Group |
| `ssh_connection` | Comando SSH para conectar |
| `private_key_path` | Ruta a la clave privada |
| `traefik_urls` | URLs de Traefik y dashboard |

## Ejemplos

Ver carpeta `examples/` para ejemplos completos.

```bash
cd examples/basic
cp terraform.tfvars.example terraform.tfvars
# Editar terraform.tfvars con tus valores
terraform init
terraform apply
```

## Agregar Servicios Docker

Usa labels en tu `docker-compose.yml`:

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

## Estructura del Módulo

```
├── main.tf                    # Recursos AWS
├── variables.tf               # Variables de entrada
├── outputs.tf                 # Outputs del módulo
├── provider.tf                # Provider config
├── templates/
│   └── user-data-traefik.sh # Script de bootstrap
└── examples/
    └── basic/                # Ejemplo de uso
```
