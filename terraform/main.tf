###########################################
# Terraform & Provider Configuration
###########################################
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1"   # or your preferred region
}

###########################################
# Use Existing SSH Key
###########################################
data "aws_lightsail_key_pair" "existing" {
  name = "hello-world"    # same name as your existing AWS key pair
}

###########################################
# Lightsail Instance (no vCPU limits)
###########################################
resource "aws_lightsail_instance" "web" {
  name              = "my-static-page"
  availability_zone = "eu-north-1a"
  blueprint_id      = "ubuntu_22_04"   # Ubuntu 22.04 LTS
  bundle_id         = "nano_2_0"       # smallest plan (no quotas)
  key_pair_name     = data.aws_lightsail_key_pair.existing.name

  tags = {
    Name = "MyStaticPage"
  }
}

###########################################
# Networking: open ports 22 + 80
###########################################
resource "aws_lightsail_instance_public_ports" "web_ports" {
  instance_name = aws_lightsail_instance.web.name

  port_info {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }

  port_info {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
  }
}

###########################################
# Outputs for CI/CD
###########################################
output "public_ip" {
  description = "Public IP of the Lightsail instance"
  value       = aws_lightsail_instance.web.public_ip_address
}
