terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-north-1" # Byt till din valda AWS-region om behövs
}

# Skapa nyckelpar i AWS från din lokala publika nyckel
resource "aws_key_pair" "app_key" {
  key_name   = "image-app-key"
  public_key = file("${path.module}/keys/image-app-key.pem.pub")
}

# Säkerhetsgrupp för HTTP (80) och SSH (22)
resource "aws_security_group" "web_sg" {
  name        = "bildgenerator-sg"
  description = "Tillat HTTP och SSH"

  ingress {
    description = "HTTP fran varlden"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
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

# EC2 Instans (Amazon Linux 2023)
resource "aws_instance" "web" {
  ami                         = "ami-0c4fc5dcabc9df21d" # Amazon Linux 2023 AMI för eu-north-1
  instance_type               = "t3.micro"
  key_name                    = aws_key_pair.app_key.key_name
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  user_data                   = file("${path.module}/user-data.web.sh")
  user_data_replace_on_change = true

  tags = {
    Name = "ai-bildgenerator-server"
  }
}

output "ec2_public_dns_name" {
  value       = aws_instance.web.public_dns
  description = "Publik DNS for EC2-instansen"
}

output "ec2_public_ip" {
  value       = aws_instance.web.public_ip
  description = "Publik IP for EC2-instansen"
}