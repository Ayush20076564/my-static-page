###########################################
# Terraform & AWS Provider Configuration
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
  region = "us-east-1"   # ✅ Reliable & free-tier eligible region
}

###########################################
# Generate Unique Suffix (Avoid Duplicate SG Names)
###########################################
resource "random_id" "suffix" {
  byte_length = 3
}

###########################################
# Use Existing SSH Key Pair
###########################################
data "aws_key_pair" "web_key" {
  key_name = "hello-world"   # ✅ Replace with your AWS key pair name
}

###########################################
# Latest Ubuntu 22.04 ARM64 AMI (for t4g.micro)
###########################################
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-arm64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]  # Canonical (official Ubuntu AMIs)
}

###########################################
# Security Group (Allow SSH & HTTP)
###########################################
resource "aws_security_group" "web_sg" {
  name        = "web-sg-${random_id.suffix.hex}"
  description = "Allow SSH (22) and HTTP (80) access"

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP access"
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
    Name = "web-sg-${random_id.suffix.hex}"
  }
}

###########################################
# EC2 Instance (Free-Tier ARM Instance)
###########################################
resource "aws_instance" "web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t4g.micro"     # ✅ ARM-based, free-tier eligible
  key_name               = data.aws_key_pair.web_key.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "MyStaticPage"
  }
}

###########################################
# Outputs (for GitHub Actions)
###########################################
output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "security_group_name" {
  description = "Security group name"
  value       = aws_security_group.web_sg.name
}

output "ami_used" {
  description = "AMI ID used for EC2"
  value       = data.aws_ami.ubuntu.id
}
