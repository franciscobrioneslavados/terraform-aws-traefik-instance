variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "CIDR_block" {
  description = "CIDR block of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "traefik-proxy"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "owner_name" {
  description = "Owner name for tagging"
  type        = string
}

variable "traefik_instance_type" {
  description = "EC2 instance type for Traefik"
  type        = string
  default     = "t3.micro"
}

variable "ssh_allowed_cidr" {
  description = "CIDR blocks allowed for SSH"
  type        = list(string)
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
