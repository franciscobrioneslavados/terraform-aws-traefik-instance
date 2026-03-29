variable "vpc_id" {
  description = "ID of the VPC where the Traefik Instance will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for Traefik deployment (first one will be used)"
  type        = list(string)
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
  default     = "traefik-proxy"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "development"
}

variable "owner_name" {
  description = "Owner name for resource tagging"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the Traefik Instance (e.g., t3.micro, t2.micro)"
  type        = string
  default     = "t3.micro"
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed for SSH access. Empty list disables SSH access."
  type        = list(string)
  default     = []
}

variable "ami_id" {
  description = "Custom AMI ID to use. Null uses Ubuntu 22.04."
  type        = string
  default     = null
}

variable "key_name" {
  description = "Existing key pair name to use"
  type        = string
  default     = null
}

variable "managed_by" {
  description = "ManagedBy tag value"
  type        = string
  default     = "Terraform"
}

variable "domain_name" {
  description = "Domain name (optional, leave empty for IP-only)"
  type        = string
  default     = ""
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token (optional, leave empty for no SSL)"
  type        = string
  default     = ""
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID (optional)"
  type        = string
  default     = ""
}

variable "traefik_dashboard_enabled" {
  description = "Enable Traefik dashboard"
  type        = bool
  default     = false
}

variable "traefik_dashboard_users" {
  description = "Dashboard basic auth users (htpasswd format, optional)"
  type        = string
  default     = ""
}

variable "enable_cloudwatch_agent" {
  description = "Enable CloudWatch Agent for monitoring"
  type        = bool
  default     = false
}
