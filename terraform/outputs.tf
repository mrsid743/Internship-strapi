# terraform/outputs.tf

output "public_ip" {
  description = "Public IP address of the Strapi EC2 instance."
  value       = aws_instance.strapi_server.public_ip
}

output "public_dns" {
  description = "Public DNS of the Strapi EC2 instance."
  value       = aws_instance.strapi_server.public_dns
}
