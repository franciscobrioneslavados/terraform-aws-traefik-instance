output "traefik_instance_id" {
  description = "ID of the Traefik Instance"
  value       = aws_instance.traefik_proxy.id
}

output "traefik_instance_arn" {
  description = "ARN of the Traefik Instance"
  value       = aws_instance.traefik_proxy.arn
}

output "traefik_instance_public_ip" {
  description = "Public IP (EIP) of the Traefik Instance"
  value       = aws_eip.traefik.public_ip
}

output "traefik_instance_private_ip" {
  description = "Private IP of the Traefik Instance"
  value       = aws_instance.traefik_proxy.private_ip
}

output "traefik_security_group_id" {
  description = "Security Group ID of the Traefik Instance"
  value       = aws_security_group.traefik.id
}

output "key_pair_name" {
  description = "Key pair name used by the Traefik Instance"
  value       = var.key_name != null ? var.key_name : aws_key_pair.key_pair[0].key_name
}

output "private_key_file" {
  description = "Local path to the private key file (if auto-generated)"
  value       = var.key_name != null ? null : "${path.module}/${var.environment}-${var.project_name}-key.pem"
}

output "ssh_command" {
  description = "SSH command to connect to the Traefik Instance"
  value       = "ssh -i ${var.key_name != null ? "~/.ssh/${var.key_name}.pem" : "${var.environment}-${var.project_name}-key.pem"} ubuntu@${aws_eip.traefik.public_ip}"
}

output "chmod_command" {
  description = "Command to set correct permissions on the private key"
  value       = var.key_name != null ? null : "chmod 400 ${var.environment}-${var.project_name}-key.pem"
}

output "traefik_urls" {
  description = "Traefik URLs"
  value = {
    http      = "http://${aws_eip.traefik.public_ip}"
    https     = "https://${aws_eip.traefik.public_ip}"
    dashboard = var.traefik_dashboard_enabled ? "http://${aws_eip.traefik.public_ip}:8080/dashboard/" : "disabled"
  }
}
