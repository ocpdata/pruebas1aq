output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.arcadia.id
}

output "public_ip" {
  description = "EC2 public IPv4 address"
  value       = aws_instance.arcadia.public_ip
}

output "public_dns" {
  description = "EC2 public DNS name"
  value       = aws_instance.arcadia.public_dns
}

output "security_group_id" {
  description = "Security group attached to the EC2 instance"
  value       = aws_security_group.arcadia.id
}
