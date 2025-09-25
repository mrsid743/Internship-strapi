variable "aws_region" {
  description = "AWS region"
  default     = "ap-south-1"
}

variable "image_tag" {
  description = "Docker image tag for Strapi"
  type        = string
}

variable "strapi_app_keys" {
  description = "Strapi APP_KEYS"
  type        = string
}

variable "strapi_api_token_salt" {
  description = "Strapi API_TOKEN_SALT"
  type        = string
}

variable "strapi_admin_jwt_secret" {
  description = "Strapi ADMIN_JWT_SECRET"
  type        = string
}

variable "strapi_jwt_secret" {
  description = "Strapi JWT_SECRET"
  type        = string
}
