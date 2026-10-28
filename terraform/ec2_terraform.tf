terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region  = "ap-south-1"
  profile = "terraform-user"   # remove this line if you use environment variables
}

# Firewall rule: allow SSH
resource "aws_security_group" "ssh_sg" {
  name = "allow-ssh"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # better: put your own IP, like "1.2.3.4/32"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# The EC2 server
resource "aws_instance" "my_ec2" {
  ami                    = "ami-xxxxxxxxxxxxxxxxx"  # find the right AMI ID for your region
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ssh_sg.id]
  # key_name             = "your-key-pair-name"     # needed if you want to SSH in

  tags = {
    Name = "my-first-terraform-ec2"
  }
}

output "public_ip" {
  value = aws_instance.my_ec2.public_ip
}
