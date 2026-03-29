output "traefik_public_ip" {
  description = "Public IP of Traefik server"
  value       = aws_eip.traefik.public_ip
}

output "traefik_public_dns" {
  description = "Public DNS of Traefik server"
  value       = aws_eip.traefik.public_dns
}

output "traefik_instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.traefik_proxy.id
}

output "traefik_security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.traefik.id
}

output "ssh_connection" {
  description = "SSH command to connect"
  value       = "ssh -i '${aws_key_pair.key_pair.key_name}.pem' ubuntu@${aws_eip.traefik.public_dns}"
}

output "private_key_path" {
  description = "Path to private key"
  value       = "${path.module}/${aws_key_pair.key_pair.key_name}.pem"
}

output "traefik_urls" {
  description = "Traefik URLs"
  value = {
    http      = "http://${aws_eip.traefik.public_ip}"
    https     = "https://${aws_eip.traefik.public_ip}"
    dashboard = var.traefik_dashboard_enabled ? "http://${aws_eip.traefik.public_ip}:8080/dashboard/" : "disabled"
  }
}
