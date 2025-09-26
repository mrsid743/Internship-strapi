# terraform/main.tf

# Configure the AWS provider
provider "aws" {
  region = var.aws_region
}

# Get the AWS account ID for constructing the ECR image URI
data "aws_caller_identity" "current" {}

# Find the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Find the existing IAM instance profile for ECR access
data "aws_iam_instance_profile" "existing_profile" {
  name = var.instance_profile_name
}

# Define the Security Group for the Strapi instance
resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg-sid"
  description = "Allow SSH, HTTP, and Strapi traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH access from anywhere"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from anywhere"
  }

  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow access to Strapi default port"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "strapi-sg-sid"
  }
}

# Define the EC2 Instance
resource "aws_instance" "strapi_server" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]
  iam_instance_profile   = data.aws_iam_instance_profile.existing_profile.name

  # User data script to install Docker, pull the image from ECR, and run the container
  user_data = <<-EOF
              #!/bin/bash
              # Install Docker
              yum update -y
              yum install -y docker
              service docker start
              usermod -a -G docker ec2-user

              # Login to ECR
              aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com

              # Stop and remove existing Strapi container if it exists
              docker ps -q --filter "name=strapi" | grep -q . && docker stop strapi && docker rm -fv strapi

              # Pull and run the new Strapi image
              docker pull ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repo_name}:${var.strapi_image_tag}
              docker run -d --name strapi -p 1337:1337 --restart always ${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.ecr_repo_name}:${var.strapi_image_tag}
              EOF

  tags = {
    Name = "Strapi-Instance-Siddhant"
  }
}
