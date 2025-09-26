provider "aws" {
  region = var.aws_region
}

# --- Data Sources for Networking ---

# Find the default VPC
data "aws_vpc" "default" {
  default = true
}

# Find a default public subnet (first AZ in region)
data "aws_subnet" "default" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "${var.aws_region}a"
}

# --- Managed Security Group ---

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

# --- Data Source for IAM Instance Profile (already created outside Terraform) ---

data "aws_iam_instance_profile" "existing_profile" {
  name = "ec2_ecr_full_access_profile"
}

# --- Latest Amazon Linux 2 AMI ---
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# --- EC2 Instance Resource ---

resource "aws_instance" "strapi_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnet.default.id
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]
  iam_instance_profile   = data.aws_iam_instance_profile.existing_profile.name
  key_name               = var.aws_key_pair_name

  user_data = templatefile("${path.module}/user_data.tftpl", {
    aws_region              = var.aws_region
    ecr_repo_url            = var.ecr_repository_url
    image_tag               = var.image_tag
    strapi_app_keys         = var.strapi_app_keys
    strapi_api_token_salt   = var.strapi_api_token_salt
    strapi_admin_jwt_secret = var.strapi_admin_jwt_secret
    strapi_jwt_secret       = var.strapi_jwt_secret
  })

  tags = {
    Name = "Strapi-Server-Final"
  }
}

# --- Outputs ---

output "strapi_server_public_ip" {
  value = aws_instance.strapi_server.public_ip
}
