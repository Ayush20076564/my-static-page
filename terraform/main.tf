###########################################
# Terraform & Provider Configuration
###########################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"  # ✅ Adjust only if your AWS keypair is in a different region
}

###########################################
# Generate Unique Suffix for Resource Names
###########################################
resource "random_id" "suffix" {
  byte_length = 3
}

###########################################
# Use Existing SSH Key (replace name if needed)
###########################################
data "aws_key_pair" "web_key" {
  key_name = "hello-world"  # ✅ Ensure this key exists in AWS EC2 → Key Pairs
}

###########################################
# Automatically Fetch Latest Ubuntu 22.04 AMI
###########################################
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]  # Canonical (official Ubuntu images)
}

###########################################
# Security Group (with unique name)
###########################################
resource "aws_security_group" "web_sg" {
  name        = "web_sg-${random_id.suffix.hex}"
  description = "Allow SSH (22) and HTTP (80)"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
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
    Name = "web_sg-${random_id.suffix.hex}"
  }
}

###########################################
# EC2 Instance (Free-Tier Eligible)
###########################################
resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t4g.micro"            # ✅ free-tier eligible in eu-north-1
  key_name               = data.aws_key_pair.web_key.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "MyStaticPage"
  }
}

###########################################
# Outputs for CI/CD (GitHub Actions)
###########################################
output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "security_group_name" {
  description = "Unique name of the security group"
  value       = aws_security_group.web_sg.name
}

output "ami_used" {
  description = "Ubuntu AMI ID used for EC2"
  value       = data.aws_ami.ubuntu.id
}
