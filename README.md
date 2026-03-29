# AWS EC2 Traefik Proxy Module

A Terraform module to deploy a **Traefik v3** reverse proxy in a single EC2 instance.

## Features

- Traefik v3 as reverse proxy and load balancer
- Docker and Docker Compose pre-installed
- Automatic service discovery via Docker socket
- Configurable dashboard with optional basic auth
- Security Group with HTTP (80), HTTPS (443), SSH (22)
- Elastic IP association
- Optional Cloudflare SSL integration
- Terraform Registry compatible

## Architecture

```
                        Internet
                            |
                            v
                  +-------------------+
                  |      ALB / NLB    | (optional)
                  +-------------------+
                            |
                            v
                 +--------------------+
                 |   Traefik EC2      |
                 |   (t3.micro)       |
                 +--------------------+
                 |  :80  HTTP         |
                 |  :443 HTTPS        |
                 |  :8080 Dashboard   |
                 +--------------------+
                            |
                 +-----------+-----------+
                 |                       |
                 v                       v
         +--------------+        +--------------+
         | Docker       |        | Docker       |
         | Container 1 |        | Container 2  |
         +--------------+        +--------------+
```

## Usage

### Basic Usage

```hcl
module "traefik_proxy" {
  source = "github.com/franciscobrioneslavados/terraform-aws-traefik-instance"

  vpc_id            = "vpc-xxxxxxxxxxxxx"
  public_subnet_ids = ["subnet-xxxxxxxxxxxxx"]

  project_name = "my-project"
  environment  = "dev"
  owner_name   = "John Doe"

  ssh_allowed_cidrs = ["your-ip/32"]
}
```

### With Dashboard Enabled

```hcl
module "traefik_proxy" {
  source = "github.com/franciscobrioneslavados/terraform-aws-traefik-instance"

  vpc_id            = "vpc-xxxxxxxxxxxxx"
  public_subnet_ids = ["subnet-xxxxxxxxxxxxx"]

  project_name               = "my-project"
  environment                = "dev"
  owner_name                 = "John Doe"
  ssh_allowed_cidrs         = ["your-ip/32"]

  traefik_dashboard_enabled = true
  # traefik_dashboard_users = "admin:$apr1$H6uskkkW$IgXLP6ewTrSuBkTrqE8wj/" # htpasswd
}
```

### With Existing Key Pair

```hcl
module "traefik_proxy" {
  source = "github.com/franciscobrioneslavados/terraform-aws-traefik-instance"

  # ... other variables ...

  key_name = "my-existing-key"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5 |
| aws | >= 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| vpc_id | VPC ID where the Traefik Instance will be deployed | `string` | - | yes |
| public_subnet_ids | List of public subnet IDs (first one used) | `list(string)` | - | yes |
| project_name | Project name for tagging | `string` | `"traefik-proxy"` | no |
| environment | Environment name (dev, staging, prod) | `string` | `"development"` | no |
| owner_name | Owner name for tagging | `string` | - | yes |
| instance_type | EC2 instance type | `string` | `"t3.micro"` | no |
| ssh_allowed_cidrs | CIDR blocks for SSH access (empty disables) | `list(string)` | `[]` | no |
| ami_id | Custom AMI ID (null = Ubuntu 22.04) | `string` | `null` | no |
| key_name | Existing key pair name (null = auto-generate) | `string` | `null` | no |
| managed_by | ManagedBy tag value | `string` | `"Terraform"` | no |
| domain_name | Domain name for SSL (optional) | `string` | `""` | no |
| cloudflare_api_token | Cloudflare API token (optional) | `string` | `""` | no |
| cloudflare_zone_id | Cloudflare zone ID (optional) | `string` | `""` | no |
| traefik_dashboard_enabled | Enable Traefik dashboard | `bool` | `false` | no |
| traefik_dashboard_users | Dashboard basic auth users (htpasswd) | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| traefik_instance_id | ID of the Traefik Instance |
| traefik_instance_arn | ARN of the Traefik Instance |
| traefik_instance_public_ip | Public IP (EIP) of the Traefik Instance |
| traefik_instance_private_ip | Private IP of the Traefik Instance |
| traefik_security_group_id | Security Group ID |
| key_pair_name | Key pair name used |
| private_key_file | Local path to private key (if auto-generated) |
| ssh_command | SSH command to connect to Traefik Instance |
| chmod_command | Command to set key permissions |
| traefik_urls | Traefik HTTP/HTTPS URLs |

## Adding Docker Services

Use Docker labels in your `docker-compose.yml`:

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

  another-app:
    image: another-app:latest
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.another.rule=Host(`app.example.com`)"
      - "traefik.http.services.another.loadbalancer.server.port=8080"
    networks:
      - traefik-public

networks:
  traefik-public:
    external: true
```

## Testing / Validation

1. Connect to the Traefik Instance:
   ```bash
   ssh -i your-key.pem ubuntu@<TRAEFIK_PUBLIC_IP>
   ```

2. Verify Traefik is running:
   ```bash
   docker ps | grep traefik
   ```

3. Check Traefik logs:
   ```bash
   docker logs traefik
   ```

4. Access the dashboard (if enabled):
   ```bash
   curl http://<TRAEFIK_PUBLIC_IP>:8080/api/http/routers
   ```

5. Test HTTP routing:
   ```bash
   curl http://<TRAEFIK_PUBLIC_IP>
   ```

## Notes

- The EC2 instance must have **source_dest_check = false** (handled automatically)
- The EIP is associated to persist the public IP
- Traefik discovers services via Docker socket
- The security group allows HTTP/HTTPS from 0.0.0.0/0
- SSH access is restricted to specified CIDRs (or disabled if empty)
- For production, use SSL/TLS certificates via Let's Encrypt or Cloudflare

## Examples

See `examples/basic/` for complete usage examples.

```bash
cd examples/basic
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform apply
```

## Versioning

This module uses [GitHub Releases](https://github.com/franciscobrioneslavados/terraform-aws-traefik-instance/releases) for versioning.

### Using a Specific Version

```hcl
module "traefik_proxy" {
  source = "git::https://github.com/franciscobrioneslavados/terraform-aws-traefik-instance.git//.?ref=v1.5.2"

  # ... variables
}
```

### Using Latest (main branch)

```hcl
module "traefik_proxy" {
  source = "git::https://github.com/franciscobrioneslavados/terraform-aws-traefik-instance.git//.?ref=main"

  # ... variables
}
```

**Note**: Using `main` branch may include breaking changes. Recommended for development only.

## References

- [Traefik v3 Documentation](https://doc.traefik.io/traefik/)
- [Terraform aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
- [AWS EC2](https://docs.aws.amazon.com/ec2/)

## License

MIT License - see [LICENSE](LICENSE) for details.
