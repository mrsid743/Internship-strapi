# terraform/variables.tf

variable "aws_region" {
  description = "The AWS region to deploy the infrastructure in."
  type        = string
  default     = "ap-south-1" # Default region set to Mumbai
}

variable "project_name" {
  description = "A unique name for the project, used for naming resources."
  type        = string
  default     = "strapi-ecs-fargate"
}

variable "ecr_repository_name" {
  description = "The name of the pre-existing ECR repository."
  type        = string
  default     = "siddhant-strapi"
}

variable "ec2_key_name" {
  description = "The name of the EC2 key pair."
  type        = string
  default     = "strapi-mumbai-key"
}

variable "container_cpu" {
  description = "The number of CPU units (e.g., 256 for 0.25 vCPU) to reserve for the container."
  type        = number
  default     = 256
}

variable "container_memory" {
  description = "The amount of memory (in MiB) to reserve for the container."
  type        = number
  default     = 512
}

variable "strapi_port" {
  description = "The port the Strapi container listens on."
  type        = number
  default     = 1337
}

