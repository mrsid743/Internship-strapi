output "instance_id" {
  description = "The ID of the EC2 instance."
  value       = aws_instance.strapi_server.id
}

output "public_ip" {
  description = "The public IP address of the EC2 instance."
  value       = aws_instance.strapi_server.public_ip
}

output "ssh_command" {
  description = "Command to SSH into the instance."
  value       = "ssh -i strapi-mumbai-key.pem ec2-user@${aws_instance.strapi_server.public_ip}"
}

