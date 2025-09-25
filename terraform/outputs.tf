output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.strapi_ecr_repo.repository_url
}

output "strapi_server_public_ip" {
  description = "Public IP of the EC2 instance running Strapi"
  value       = aws_instance.strapi_server.public_ip
}
