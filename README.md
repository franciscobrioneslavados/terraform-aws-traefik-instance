# Terraform AWS EC2 Traefik Proxy Module

Módulo de Terraform para desplegar un proxy reverso **Traefik v3** en una instancia EC2.

## Usar como Módulo

```hcl
module "traefik_proxy" {
  source = "github.com/franciscobrioneslavados/terraform-aws-traefik-instance"

  vpc_id            = "vpc-xxxxxxxx"
  public_subnet_ids = ["subnet-xxxxxxxx"]

  project_name = "traefik-proxy"
  environment  = "production"
  owner_name   = "Team"

  ssh_allowed_cidrs = ["tu-ip/32"]
}
```

## Inputs

| Variable | Tipo | Default | Descripción |
|----------|------|---------|-------------|
| `vpc_id` | string | - | ID de la VPC |
| `public_subnet_ids` | list(string) | - | IDs de subnets públicas |
| `project_name` | string | `"traefik-proxy"` | Nombre del proyecto |
| `environment` | string | `"development"` | Entorno |
| `owner_name` | string | - | Dueño del recurso |
| `instance_type` | string | `"t3.micro"` | Tipo de instancia EC2 |
| `ssh_allowed_cidrs` | list(string) | `[]` | CIDRs permitidos para SSH |
| `ami_id` | string | `null` | AMI personalizada (null usa Ubuntu 22.04) |
| `key_name` | string | `null` | Key pair existente (null genera uno nuevo) |
| `managed_by` | string | `"Terraform"` | Valor del tag ManagedBy |
| `domain_name` | string | `""` | Dominio (opcional) |
| `cloudflare_api_token` | string | `""` | Token Cloudflare (opcional) |
| `cloudflare_zone_id` | string | `""` | Zone ID Cloudflare (opcional) |
| `traefik_dashboard_enabled` | bool | `false` | Habilitar dashboard |
| `traefik_dashboard_users` | string | `""` | Users dashboard (htpasswd) |

## Outputs

| Output | Descripción |
|--------|-------------|
| `traefik_instance_id` | ID de la instancia EC2 |
| `traefik_instance_arn` | ARN de la instancia EC2 |
| `traefik_instance_public_ip` | IP pública (EIP) de la instancia |
| `traefik_instance_private_ip` | IP privada de la instancia |
| `traefik_security_group_id` | ID del Security Group |
| `key_pair_name` | Nombre del key pair usado |
| `private_key_file` | Ruta local a la clave privada (si se genera automáticamente) |
| `ssh_command` | Comando SSH para conectar |
| `chmod_command` | Comando para setear permisos correctos en la clave privada |
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
├── versions.tf                # Versiones de Terraform y providers
├── templates/
│   └── user-data-traefik.sh # Script de bootstrap
└── examples/
    └── basic/                # Ejemplo de uso
```
