# terraform/variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "ap-south-1"
}

variable "strapi_image_tag" {
  description = "The tag of the Strapi Docker image to deploy."
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type."
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "The name of the EC2 key pair for SSH access."
  type        = string
  default     = "strapi-mumbai-key"
}

variable "ecr_repo_name" {
  description = "The name of the ECR repository."
  type        = string
  default     = "siddhant-strapi"
}

variable "instance_profile_name" {
  description = "The name of the IAM instance profile with ECR access."
  type        = string
  default     = "ec2_ecr_full_access_profile"
}
