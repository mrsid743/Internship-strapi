# outputs.tf
# Defines the output values from our Terraform configuration.

output "public_ip" {
  description = "The public IP address of the Strapi EC2 instance."
  value       = aws_instance.strapi_server.public_ip
}

output "ssh_command" {
  description = "Command to SSH into the EC2 instance."
  value       = "ssh -i <path_to_your_private_key> ec2-user@${aws_instance.strapi_server.public_ip}"
}
