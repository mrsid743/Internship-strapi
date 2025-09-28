# terraform/main.tf

provider "aws" {
  region = var.aws_region
}

locals {
  project_name = var.project_name
  tags = {
    Project   = local.project_name
    ManagedBy = "Terraform"
  }
}

