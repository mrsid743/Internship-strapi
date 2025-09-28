# terraform/ecr.tf

# This data source fetches information about a pre-existing ECR repository.
# Terraform will not create or manage this repository, only reference it.
data "aws_ecr_repository" "strapi_app" {
  name = var.ecr_repository_name
}

