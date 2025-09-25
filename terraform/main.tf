provider "aws" {
  region = var.aws_region
}

# --- Data Sources ---

# Get the default VPC to deploy resources into
data "aws_vpc" "default" {
  default = true
}

# Get all subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Find the latest Amazon Linux 2 AMI automatically
# This avoids using a hardcoded, region-specific AMI ID
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}


# --- Resources ---

# ECR Repository to store the Strapi Docker image
resource "aws_ecr_repository" "strapi_ecr_repo" {
  name = "siddhant-strapi"
}

# Security Group for the EC2 instance
resource "aws_security_group" "strapi_sg" {
  name        = "strapi-security-sid"
  description = "Allow inbound traffic for Strapi application"
  vpc_id      = data.aws_vpc.default.id

  # Ingress rule for the Strapi application on port 1337
  ingress {
    description = "Strapi App"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allows access from any IP
  }

  # Egress rule to allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Strapi-SG"
  }
}

# IAM Role for the EC2 instance
resource "aws_iam_role" "ec2_strapi_role" {
  name = "ec2_strapi_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

# Attach policy to allow pulling images from ECR
resource "aws_iam_role_policy_attachment" "ecr_access" {
  role       = aws_iam_role.ec2_strapi_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly" # ReadOnly is more secure
}

# Attach policy for AWS Systems Manager (for secure access)
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_strapi_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile to attach the role to the EC2 instance
resource "aws_iam_instance_profile" "strapi_instance_profile" {
  name = "ec2_strapi_instance_profile"
  role = aws_iam_role.ec2_strapi_role.name
}

# EC2 Instance to run the Strapi application
resource "aws_instance" "strapi_server" {
  ami                      = data.aws_ami.amazon_linux_2.id # Dynamically uses the latest AMI
  instance_type            = "t2.micro"
  subnet_id                = element(data.aws_subnets.default.ids, 0)
  vpc_security_group_ids   = [aws_security_group.strapi_sg.id]
  iam_instance_profile     = aws_iam_instance_profile.strapi_instance_profile.name
  associate_public_ip_address = true # Ensure a public IP is assigned

  user_data = templatefile("${path.module}/user_data.tftpl", {
    aws_region              = var.aws_region
    ecr_repo_url            = aws_ecr_repository.strapi_ecr_repo.repository_url
    image_tag               = var.image_tag
    strapi_app_keys         = var.strapi_app_keys
    strapi_api_token_salt   = var.strapi_api_token_salt
    strapi_admin_jwt_secret = var.strapi_admin_jwt_secret
    strapi_jwt_secret       = var.strapi_jwt_secret
  })

  tags = {
    Name = "Strapi-Server"
  }
}
