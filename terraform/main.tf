provider "aws" {
  region = var.aws_region
}

# --- Data Sources for Networking ---

# Find the default VPC
data "aws_vpc" "default" {
  default = true
}

# Find a default public subnet
data "aws_subnet" "default" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "${var.aws_region}a"
}

# --- Managed Security Group ---

# CREATE and manage the security group with Terraform
resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg-sid"
  description = "Allow SSH, HTTP, and Strapi default port"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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

  tags = {
    Name = "strapi-sg-sid"
  }
}

# --- Data Source for IAM ---

# Find the existing IAM instance profile
data "aws_iam_instance_profile" "existing_profile" {
  name = "ec2_ecr_full_access_profile"
}


# --- EC2 Instance Resource ---

resource "aws_instance" "strapi_server" {
  ami                    = "ami-0abcdef1234567890" # Amazon Linux 2023 for ap-south-1
  instance_type          = "t2.micro" 
  subnet_id              = data.aws_subnet.default.id
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]
  iam_instance_profile   = data.aws_iam_instance_profile.existing_profile.name
  key_name               = "strapi-mumbai-key"

  # Corrected user_data script for EC2 user
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker aws-cli
              systemctl start docker
              systemctl enable docker
              usermod -a -G docker ec2-user
              
              # Log in to AWS ECR
              aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.ecr_repository_url}
              
              # Pull and run the specified Strapi image
              docker pull ${var.ecr_repository_url}:${var.image_tag}
              docker run -d -p 80:1337 --name strapi-app ${var.ecr_repository_url}:${var.image_tag}
              EOF

  tags = {
    Name = "Strapi-Server-Final-Fixed"
  }
}
