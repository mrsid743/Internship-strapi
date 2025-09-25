# ... (VPC, Subnet, Security Group code is still here) ...

# --- IAM ---

# Look up an EXISTING IAM instance profile by its name.
# This now points to the role from your screenshot.
data "aws_iam_instance_profile" "existing_profile" {
  name = "ec2_ecr_full_access_role"
}


# Key pair for SSH access
resource "aws_key_pair" "deployer_key" {
# ... (rest of the key pair code) ...
}

# --- EC2 Instance ---

resource "aws_ec2_instance" "strapi_server" {
  ami           = "ami-0f5ee92e2d63afc18" # Amazon Linux 2023 AMI for ap-south-1
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.strapi_public_subnet.id
  vpc_security_group_ids = [aws_security_group.strapi_sg.id]
  key_name      = aws_key_pair.deployer_key.key_name

  # This line is UPDATED to use the data source
  iam_instance_profile = data.aws_iam_instance_profile.existing_profile.name

  # ... (user_data and tags) ...
}

