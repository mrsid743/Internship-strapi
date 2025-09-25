variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "ap-south-1"
}

variable "ecr_repository_url" {
  description = "The URL of the ECR repository (e.g., 123456789012.dkr.ecr.***.amazonaws.com)."
  type        = string
}

variable "image_tag" {
  description = "The tag of the Docker image to deploy."
  type        = string
}

variable "ssh_public_key" {
  description = "The public key to use for SSH access to the EC2 instance."
  type        = string
  sensitive   = true
}
