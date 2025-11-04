provider "aws" {
  region = "us-east-1c" # or your preferred regions
}

# Security group for HTTP + SSH access
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow HTTP and SSH"

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
}

# EC2 Instance
resource "aws_instance" "web" {
  ami           = "ami-0360c520857e3138f"  # Ubuntu 22.04 (eu-west-1)
  instance_type = "t3.micro"
  key_name      = "Aj website"                 # use your AWS key pair name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt update -y
              apt install -y docker.io
              systemctl enable docker
              systemctl start docker
              EOF

  tags = {
    Name = "aj-static-web"
  }
}

# Output the EC2 public IP
output "public_ip" {
  value = aws_instance.web.public_ip
}
