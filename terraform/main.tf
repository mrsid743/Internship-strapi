provider "aws" {
  region = var.aws_region
}

# --- Use Existing Networking ---

# Look up the default VPC in your account
data "aws_vpc" "default" {
  default = true
}

# Look up a public subnet within the default VPC
data "aws_subnet" "default" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "${var.aws_region}a" # Using 'a' zone, can be changed if needed
}

# CREATE and manage the security group with Terraform
resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg-sid"
  description = "Allow SSH, HTTP, and Strapi default port"
  vpc_id      = data.aws_vpc.default.id # Use the default VPC ID

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


# --- Use Existing IAM Role ---

# Look up the existing IAM Role
data "aws_iam_role" "existing_role" {
  name = "ec2_ecr_full_access_role"
}

# Create an Instance Profile and attach the existing role to it
resource "aws_iam_instance_profile" "strapi_instance_profile" {
  name = "ec2_ecr_full_access_profile"
  role = data.aws_iam_role.existing_role.name
}

# --- EC2 Instance ---

resource "aws_instance" "strapi_server" {
  ami                    = "ami-0f5ee92e2d63afc18" # Amazon Linux 2023 AMI for ap-south-1 (Mumbai)
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnet.default.id # Use the default subnet ID
  vpc_security_group_ids = [aws_security_group.strapi_sg.id] # Use the new SG resource
  key_name               = "strapi-mumbai-key"
  iam_instance_profile   = aws_iam_instance_profile.strapi_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y docker
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              
              # Install docker-compose
              sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              sudo chmod +x /usr/local/bin/docker-compose

              # Log in to ECR
              aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.ecr_repository_url}
              
              # Pull and run the docker image
              docker pull ${var.ecr_repository_url}:${var.image_tag}
              docker run -d -p 80:1337 --name strapi-app ${var.ecr_repository_url}:${var.image_tag}
              EOF

  tags = {
    Name = "Strapi-Server"
  }
}

