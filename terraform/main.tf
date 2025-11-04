provider "aws" {
  region = "eu-north-1"
}

data "aws_key_pair" "web_key" {
  key_name = "hello-world"
}

resource "aws_security_group" "web_sg" {
  name        = "web_sg"
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
    Name = "web_sg"
  }
}

resource "aws_instance" "web" {
  ami                    = "ami-0f3e4c7d7d6f5a1c4" # Ubuntu 22.04 (eu-north-1)
  instance_type          = "t3.micro"
  key_name               = data.aws_key_pair.web_key.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "MyStaticPage"
  }
}

output "public_ip" {
  description = "EC2 public IP"
  value       = aws_instance.web.public_ip
}
