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
  region = "eu-north-1"   # ✅ use same region as your keypair
}

###########################################
# Generate Unique Suffix for Resource Names
###########################################
resource "random_id" "suffix" {
  byte_length = 3
}

###########################################
# Use Existing SSH Key
###########################################
data "aws_key_pair" "web_key" {
  key_name = "hello-world"
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
# EC2 Instance
###########################################
resource "aws_instance" "web" {
  ami                    = "ami-0f3e4c7d7d6f5a1c4" # Ubuntu 22.04 (eu-north-1)
  instance_type          = "t3.micro"
  key_name               = data.aws_key_pair.web_key.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "MyStaticPage"
  }
}

###########################################
# Output EC2 Public IP for Ansible
###########################################
output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}
