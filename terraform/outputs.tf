# terraform/outputs.tf

# This output will display the public URL of the Application Load Balancer
# after the infrastructure is successfully deployed.
output "strapi_url" {
  description = "The public URL to access the Strapi application."
  value       = "http://${aws_lb.strapi.dns_name}"
}

# This output displays the URL of the ECR repository being used.
output "ecr_repository_url" {
  description = "The URL of the ECR repository."
  # --- THIS LINE IS CORRECTED ---
  # It now correctly references the 'data' source instead of a 'resource'.
  value       = data.aws_ecr_repository.strapi_app.repository_url
}

