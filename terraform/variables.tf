# variables.tf
# Input variables for the Terraform configuration.

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "ap-south-1"
}

variable "ecr_repository_url" {
  description = "The URL of the ECR repository (e.g., 123456789012.dkr.ecr.ap-south-1.amazonaws.com)."
  type        = string
}

variable "ecr_repository_name" {
  description = "The name of the ECR repository."
  type        = string
  default     = "siddhant-strapi"
}

variable "image_tag" {
  description = "The Docker image tag to deploy."
  type        = string
}

variable "ssh_public_key" {
  description = "The public SSH key for accessing the EC2 instance."
  type        = string
  sensitive   = true
}
