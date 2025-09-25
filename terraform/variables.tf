variable "aws_region" {
  description = "AWS region for the resources"
  type        = string
  default     = "ap-south-1"
}

variable "image_tag" {
  description = "Docker image tag for the Strapi application"
  type        = string
}

variable "strapi_app_keys" {
  description = "Strapi APP_KEYS secret"
  type        = string
  sensitive   = true
}

variable "strapi_api_token_salt" {
  description = "Strapi API_TOKEN_SALT secret"
  type        = string
  sensitive   = true
}

variable "strapi_admin_jwt_secret" {
  description = "Strapi ADMIN_JWT_SECRET secret"
  type        = string
  sensitive   = true
}

variable "strapi_jwt_secret" {
  description = "Strapi JWT_SECRET secret"
  type        = string
  sensitive   = true
}
