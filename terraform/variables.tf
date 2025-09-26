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

variable "instance_type" {
  description = "The EC2 instance type to use."
  type        = string
  default     = "t2.micro"
}

variable "aws_key_pair_name" {
  description = "The EC2 key pair name to use for SSH access."
  type        = string
  default     = "strapi-mumbai-key"
}

variable "strapi_app_keys" {
  description = "Comma-separated Strapi app keys for configuration."
  type        = string
}

variable "strapi_api_token_salt" {
  description = "Strapi API token salt."
  type        = string
}

variable "strapi_admin_jwt_secret" {
  description = "Strapi admin JWT secret."
  type        = string
}

variable "strapi_jwt_secret" {
  description = "Strapi JWT secret."
  type        = string
}

variable "ssh_public_key" {
  description = "The public SSH key for accessing the EC2 instance."
  type        = string
  sensitive   = true
}
