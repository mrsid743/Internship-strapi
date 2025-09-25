provider "aws" {
  region = var.aws_region
}

# --- Data Sources to look up EXISTING resources ---

# Find the default VPC
data "aws_vpc" "default" {
  default = true
}

# Find a default public subnet in the 'a' availability zone
data "aws_subnet" "default" {
  vpc_id            = data.aws_vpc.default.id
  availability_zone = "${var.aws_region}a"
}

# Find the existing security group by its name
data "aws_security_group" "existing_sg" {
  name   = "strapi-sg-sid"
  vpc_id = data.aws_vpc.default.id
}

# Find the existing IAM instance profile
data "aws_iam_instance_profile" "existing_profile" {
  name = "ec2_ecr_full_access_profile"
}


# --- EC2 Instance Resource ---

resource "aws_instance" "strapi_server" {
  # Use the data sources to configure the instance
  ami                    = "ami-0f5ee92e2d63afc18" # Amazon Linux 2023 for ap-south-1
  instance_type          = "t2.micro"
  subnet_id              = data.aws_subnet.default.id
  vpc_security_group_ids = [data.aws_security_group.existing_sg.id]
  iam_instance_profile   = data.aws_iam_instance_profile.existing_profile.name

  # This is the crucial part - attach the key that we know works
  key_name               = "strapi-mumbai-key"

  # Startup Script
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              service docker start
              usermod -a -G docker ec2-user
              
              # Log in to AWS ECR
              aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${var.ecr_repository_url}
              
              # Pull and run the specified Strapi image
              docker pull ${var.ecr_repository_url}:${var.image_tag}
              docker run -d -p 80:1337 --name strapi-app ${var.ecr_repository_url}:${var.image_tag}
              EOF

  tags = {
    Name = "Strapi-Server-Final"
  }
}

