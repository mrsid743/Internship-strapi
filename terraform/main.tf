# Latest Amazon Linux 2 AMI
data "aws_ami" "latest_amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Default VPC
data "aws_vpc" "default" {
  default = true
}

# All subnets in default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security group (renamed to avoid duplicate)
resource "aws_security_group" "strapi_sg" {
  name        = "strapi-sg-sid"  # renamed
  description = "Allow SSH and Strapi"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  ingress {
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Strapi"
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


# EC2 instance
resource "aws_instance" "strapi_ec2" {
  ami           = data.aws_ami.latest_amazon_linux_2.id
  instance_type = var.instance_type
  key_name      = var.key_name
  security_groups = [aws_security_group.strapi_sg.id]
  subnet_id       = length(var.subnet_id) > 0 ? var.subnet_id : data.aws_subnets.default.ids[0]

  user_data = templatefile("${path.module}/user_data.sh.tpl", {
    dockerhub_image = var.dockerhub_image
  })

  tags = {
    Name = "Strapi-Server-Final-Fixed"
  }
}
