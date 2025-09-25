# main.tf
# Defines the core AWS infrastructure for the Strapi deployment.

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

resource "aws_subnet" "strapi_public_subnet" {
  vpc_id     = aws_vpc.strapi_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true # Assign public IPs to instances in this subnet
  tags = {
    Name = "strapi-public-subnet"
  }
}

resource "aws_internet_gateway" "strapi_igw" {
  vpc_id = aws_vpc.strapi_vpc.id
  tags = {
    Name = "strapi-igw"
  }
}

resource "aws_route_table" "strapi_public_rt" {
  vpc_id = aws_vpc.strapi_vpc.id

  route {
    cidr_block = "0.0.0.0/0" # Route all outbound traffic
    gateway_id = aws_internet_gateway.strapi_igw.id
  }

  tags = {
    Name = "strapi-public-route-table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.strapi_public_subnet.id
  route_table_id = aws_route_table.strapi_public_rt.id
}

# --- Security ---
resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg"
  description = "Allow SSH and Strapi traffic"
  vpc_id      = aws_vpc.strapi_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: Open to the world. Restrict to your IP for production.
  }

  ingress {
    from_port   = 1337 # Default Strapi port
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
    Name = "strapi-security-group"
  }
}

# --- IAM Role for EC2 to access ECR ---
resource "aws_iam_role" "ec2_strapi_role" {
  name = "ec2_strapi_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_read_only_attachment" {
  role       = aws_iam_role.ec2_strapi_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_strapi_profile" {
  name = "ec2_strapi_instance_profile"
  role = aws_iam_role.ec2_strapi_role.name
}


# --- SSH Key ---
resource "aws_key_pair" "deployer_key" {
  key_name   = "strapi-deployer-key"
  public_key = var.ssh_public_key
}

# --- EC2 Instance ---
resource "aws_instance" "strapi_server" {
  ami           = "ami-0f5ee92e2d63afc18" # Amazon Linux 2 AMI for ap-south-1 (Mumbai)
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.strapi_public_subnet.id
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]
  key_name      = aws_key_pair.deployer_key.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_strapi_profile.name

  # User data script to setup and run the Strapi container
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              service docker start
              usermod -a -G docker ec2-user
              
              # Log in to ECR
              aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.ecr_repository_url}

              # Stop and remove any existing container named 'strapi'
              docker stop strapi || true
              docker rm strapi || true

              # Pull and run the new image
              docker pull ${var.ecr_repository_url}/${var.ecr_repository_name}:${var.image_tag}
              docker run -d -p 1337:1337 --name strapi ${var.ecr_repository_url}/${var.ecr_repository_name}:${var.image_tag}
              EOF

  tags = {
    Name = "Strapi-Server"
  }
}
