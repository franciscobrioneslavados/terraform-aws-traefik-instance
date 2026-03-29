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

output "ssh_command" {
  description = "SSH command to connect to the Traefik Instance"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_eip.traefik.public_ip}"
}

output "traefik_urls" {
  description = "Traefik URLs"
  value = {
    http      = "http://${aws_eip.traefik.public_ip}"
    https     = "https://${aws_eip.traefik.public_ip}"
    dashboard = var.traefik_dashboard_enabled ? "http://${aws_eip.traefik.public_ip}:8080/dashboard/" : "disabled"
  }
}
