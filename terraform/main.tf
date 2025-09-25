provider "aws" {
  region = var.aws_region
}

# ECR Repository
resource "aws_ecr_repository" "strapi_ecr_repo" {
  name = "siddhant-strapi"
}

# Security Group
resource "aws_security_group" "strapi_sg" {
  name        = "strapi-security-sid"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Role
resource "aws_iam_role" "ec2_ecr_full_access_role" {
  name = "ec2_ecr_full_access_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action   = "sts:AssumeRole"
    }]
  })
}

# Attach AWS Managed Policies
resource "aws_iam_role_policy_attachment" "ecr_full" {
  role       = aws_iam_role.ec2_ecr_full_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryFullAccess"
}

resource "aws_iam_role_policy_attachment" "ec2_full" {
  role       = aws_iam_role.ec2_ecr_full_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_ecr_full_access_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "strapi_instance_profile" {
  name = "ec2_ecr_full_access_role"
  role = aws_iam_role.ec2_ecr_full_access_role.name
}

# Get Default VPC
data "aws_vpc" "default" {
  default = true
}

# Get Subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# EC2 Instance
resource "aws_instance" "strapi_server" {
  ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2 (ap-south-1 example)
  instance_type          = "t2.micro"
  subnet_id              = element(data.aws_subnets.default.ids, 0)
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.strapi_instance_profile.name

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
