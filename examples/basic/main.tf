terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "traefik_proxy" {
  source = "../../"

  vpc_id            = var.vpc_id
  public_subnet_ids = var.public_subnet_ids

  project_name = var.project_name
  environment  = var.environment
  owner_name   = var.owner_name

  instance_type     = var.instance_type
  ssh_allowed_cidrs = var.ssh_allowed_cidrs

  domain_name               = var.domain_name
  traefik_dashboard_enabled = var.traefik_dashboard_enabled
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
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
}

variable "owner_name" {
  description = "Owner name for tagging"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Traefik"
  type        = string
  default     = "t3.micro"
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed for SSH"
  type        = list(string)
  default     = []
}

variable "domain_name" {
  description = "Domain name (optional)"
  type        = string
  default     = ""
}

variable "traefik_dashboard_enabled" {
  description = "Enable Traefik dashboard"
  type        = bool
  default     = false
}

output "traefik_instance_public_ip" {
  description = "Public IP of Traefik server"
  value       = module.traefik_proxy.traefik_instance_public_ip
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = module.traefik_proxy.ssh_command
}
