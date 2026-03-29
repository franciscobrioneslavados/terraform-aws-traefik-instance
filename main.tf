locals {
  global_tags = {
    "Environment" = var.environment
    "ManagedBy"   = var.managed_by
    "OwnerName"   = var.owner_name
    "ProjectName" = var.project_name
  }
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
    # checkov:skip=CKV_AWS_260:HTTP is required for reverse proxy
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
      # checkov:skip=CKV_AWS_24:SSH access from specific CIDRs is controlled by variable
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
      # checkov:skip=CKV_AWS_277:ICMP is required for network diagnostics from allowed CIDRs
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
    # checkov:skip=CKV_AWS_382:Egress to internet is required for reverse proxy
  }

  tags = merge(local.global_tags, {
    Name = "${var.environment}-${var.project_name}-sg"
  })
}

resource "aws_iam_instance_profile" "traefik" {
  name = "${var.environment}-${var.project_name}-instance-profile"
  role = aws_iam_role.traefik.name

  tags = merge(local.global_tags, {
    Name = "${var.project_name}-instance-profile"
  })
}

resource "aws_iam_role" "traefik" {
  name = "${var.environment}-${var.project_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = merge(local.global_tags, {
    Name = "${var.project_name}-role"
  })
}

resource "aws_iam_role_policy_attachment" "traefik_cloudwatch" {
  count      = var.enable_cloudwatch_agent ? 1 : 0
  role       = aws_iam_role.traefik.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_instance" "traefik_proxy" {
  ami           = var.ami_id != null ? var.ami_id : data.aws_ami.ubuntu_22_04[0].id
  instance_type = var.instance_type
  subnet_id     = var.public_subnet_ids[0]

  iam_instance_profile        = aws_iam_instance_profile.traefik.name
  vpc_security_group_ids      = [aws_security_group.traefik.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  source_dest_check           = false

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    # checkov:skip=CKV_AWS_79:IMDSv2 is required for reverse proxy
  }

  user_data = templatefile("${path.module}/templates/user-data-traefik.sh", {
    environment               = var.environment
    domain_name               = var.domain_name != "" ? var.domain_name : "local"
    resolver                  = cidrhost(data.aws_vpc.selected.cidr_block, 2)
    traefik_dashboard_enabled = var.traefik_dashboard_enabled
    traefik_dashboard_users   = var.traefik_dashboard_users
  })

  root_block_device {
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
    # checkov:skip=CKV_AWS_135:EBS encryption is required
  }

  tags = merge(local.global_tags, {
    Name = "ec2-${var.environment}-${var.project_name}"
  })

  # checkov:skip=CKV_AWS_88:Public IP required for reverse proxy
  # checkov:skip=CKV_AWS_126:Detailed monitoring not required for basic setup
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
