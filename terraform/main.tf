provider "aws" {
  region = var.aws_region
}

# --- Networking ---

resource "aws_vpc" "strapi_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "strapi-vpc"
  }
}

resource "aws_internet_gateway" "strapi_igw" {
  vpc_id = aws_vpc.strapi_vpc.id
  tags = {
    Name = "strapi-igw"
  }
}

resource "aws_subnet" "strapi_public_subnet" {
  vpc_id                  = aws_vpc.strapi_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags = {
    Name = "strapi-public-subnet"
  }
}

resource "aws_route_table" "strapi_public_rt" {
  vpc_id = aws_vpc.strapi_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.strapi_igw.id
  }
  tags = {
    Name = "strapi-public-rt"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.strapi_public_subnet.id
  route_table_id = aws_route_table.strapi_public_rt.id
}

resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg"
  description = "Allow SSH, HTTP, and Strapi default port"
  vpc_id      = aws_vpc.strapi_vpc.id

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
    Name = "strapi-sg"
  }
}

# --- IAM ---

data "aws_iam_instance_profile" "existing_profile" {
  name = "ec2_ecr_full_access_role"
}

# --- EC2 Instance ---

resource "aws_instance" "strapi_server" {
  ami                    = "ami-0f5ee92e2d63afc18" # Amazon Linux 2023 AMI for ap-south-1 (Mumbai)
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.strapi_public_subnet.id
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]
  key_name               = "strapi-mumbai-key" # Use existing key pair
  iam_instance_profile   = data.aws_iam_instance_profile.existing_profile.name

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

