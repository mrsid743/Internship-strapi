provider "aws" {
  region = var.aws_region
}

# --- Data Sources to use existing AWS resources ---

# Find the default VPC to avoid VpcLimitExceeded errors
data "aws_vpc" "default" {
  default = true
}

# Find a default public subnet within the default VPC
data "aws_subnet" "default" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "${var.aws_region}a"
}

# Find the existing IAM instance profile for ECR access
data "aws_iam_instance_profile" "existing_profile" {
  name = "ec2_ecr_full_access_profile"
}

# --- Managed Security Group ---

# We will let Terraform create and manage the security group to ensure it's clean
resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg-sid"
  description = "Allow SSH, HTTP, and Strapi default port"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Allow SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Strapi default port from anywhere"
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


# --- EC2 Instance Resource ---

resource "aws_instance" "strapi_server" {
  ami                    = "ami-0f5ee92e2d63afc18" # Amazon Linux 2023 for ap-south-1
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnet.default.id
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]
  iam_instance_profile   = data.aws_iam_instance_profile.existing_profile.name
  key_name               = "strapi-mumbai-key"

  # This startup script is now correct for AMAZON LINUX
  # It also includes the necessary environment variables for Strapi to start
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker awscli
              service docker start
              usermod -a -G docker ec2-user
              
              # Log in to AWS ECR using the attached IAM role
              aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.ecr_repository_url}
              
              # Pull the specified Strapi image
              docker pull ${var.ecr_repository_url}:${var.image_tag}
              
              # Run the container with the required Strapi environment variables
              docker run -d \
                -p 80:1337 \
                -e DATABASE_CLIENT=sqlite \
                -e DATABASE_FILENAME=./.tmp/data.db \
                -e JWT_SECRET=aSecretValueThatYouShouldChange1 \
                -e ADMIN_JWT_SECRET=aSecretValueThatYouShouldChange2 \
                -e APP_KEYS=aSecretValueThatYouShouldChange3,aSecretValueThatYouShouldChange4 \
                --name strapi-app \
                ${var.ecr_repository_url}:${var.image_tag}
              EOF

  tags = {
    Name = "Strapi-Server-Final"
  }
}

