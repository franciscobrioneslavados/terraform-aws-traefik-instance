locals {
  global_tags = {
    "Environment" = var.environment
    "ManagedBy"   = var.managed_by
    "OwnerName"   = var.owner_name
    "ProjectName" = var.project_name
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "ubuntu_22_04" {
  count       = var.ami_id != null ? 0 : 1
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_vpc" "vpc_info" {
  id = var.vpc_id
}

resource "aws_security_group" "traefik" {
  name        = "${var.project_name}-traefik-sg"
  description = "Security group for Traefik reverse proxy"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP from all"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS from all"
  }

  dynamic "ingress" {
    for_each = length(var.ssh_allowed_cidrs) > 0 ? [1] : []
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_allowed_cidrs
      description = "SSH access from allowed CIDRs"
    }
  }

  dynamic "ingress" {
    for_each = var.traefik_dashboard_enabled ? [1] : []
    content {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = var.ssh_allowed_cidrs
      description = "Traefik Dashboard"
    }
  }

  dynamic "ingress" {
    for_each = length(var.ssh_allowed_cidrs) > 0 ? [1] : []
    content {
      from_port   = -1
      to_port     = -1
      protocol    = "icmp"
      cidr_blocks = var.ssh_allowed_cidrs
      description = "ICMP (ping) from allowed CIDRs"
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(local.global_tags, {
    Name = "${var.environment}-${var.project_name}-sg"
  })
}

resource "tls_private_key" "key_pair" {
  count     = var.key_name != null ? 0 : 1
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  count      = var.key_name != null ? 0 : 1
  key_name   = "${var.environment}-${var.project_name}-key"
  public_key = tls_private_key.key_pair[0].public_key_openssh

  tags = merge(local.global_tags, {
    Name = "${var.project_name}-keypair"
  })
}

resource "local_file" "private_key" {
  count           = var.key_name != null ? 0 : 1
  content         = tls_private_key.key_pair[0].private_key_pem
  filename        = "${path.module}/${var.environment}-${var.project_name}-key.pem"
  file_permission = "0400"
}

resource "aws_instance" "traefik_proxy" {
  ami           = var.ami_id != null ? var.ami_id : data.aws_ami.ubuntu_22_04[0].id
  instance_type = var.instance_type
  subnet_id     = var.public_subnet_ids[0]

  vpc_security_group_ids      = [aws_security_group.traefik.id]
  key_name                    = var.key_name != null ? var.key_name : aws_key_pair.key_pair[0].key_name
  associate_public_ip_address = true
  source_dest_check           = false

  user_data = templatefile("${path.module}/templates/user-data-traefik.sh", {
    environment               = var.environment
    domain_name               = var.domain_name != "" ? var.domain_name : "local"
    resolver                  = cidrhost(data.aws_vpc.vpc_info.cidr_block, 2)
    traefik_dashboard_enabled = var.traefik_dashboard_enabled
    traefik_dashboard_users   = var.traefik_dashboard_users
  })

  root_block_device {
    volume_type           = "gp3"
    delete_on_termination = true
  }

  tags = merge(local.global_tags, {
    Name = "ec2-${var.environment}-${var.project_name}"
  })

  depends_on = [aws_key_pair.key_pair]
}

resource "aws_eip" "traefik" {
  domain = "vpc"

  tags = merge(local.global_tags, {
    Name = "${var.environment}-${var.project_name}-eip"
  })
}

resource "aws_eip_association" "traefik_eip" {
  instance_id   = aws_instance.traefik_proxy.id
  allocation_id = aws_eip.traefik.id
}
