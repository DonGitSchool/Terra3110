terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.55.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# Create a new key pair
resource "aws_key_pair" "key3" {
  key_name = "key2"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDU2YZ6ZPA9TLz+I1h36bHssAQYBqeqUpUE7iy+WXGxp6cYpk7SKRu822PbpFwmiGlFGz2iQ2QqRxA5Halu5CrIFFYSRkTqtMRTKQp1KAxey5LWUF+/YWDjMlMS0ZDbsE4mSbTcNHIZ1qI2257vywk2uI/gLPF30IM7bGA816zzHCjtM32jPaGeDnv8REKi+6LdU8Ps95af+o7sgUZn2DEe+sovMyubhpXQT/z5JGBvPDZUd+WLjcbdIYOPlc2Zfg7nnn4YIbuleGSYjlWN/xx6nfQtU9XeGHtqYjAMb8l0a7+OQ+sDntI8yDyxOsL8FU6CAp+7d1BDBL9iJYGkyYAV d00417722@ssh"
}

# Create a VPC
resource "aws_vpc" "tf-vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create a new subnet
resource "aws_subnet" "tf-subnet" {
  vpc_id     = aws_vpc.tf-vpc.id
  cidr_block = "10.0.1.0/24"
}

# Create a new security group
resource "aws_security_group" "tf-sg" {
  name = "tf-sg"
  description = "Allow port 22 and 80"
  vpc_id = aws_vpc.tf-vpc.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an internet gateway and attach it to the VPC
resource "aws_internet_gateway" "tf-ig" {
  vpc_id = aws_vpc.tf-vpc.id
}

# Create a route table and attach it to the VPC
resource "aws_route_table" "tf-r" {
  vpc_id = aws_vpc.tf-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf-ig.id
  }
}

# Associate the route table with the subnet

resource "aws_route_table_association" "tf-association" {
  subnet_id      = aws_subnet.tf-subnet.id
  route_table_id = aws_route_table.tf-r.id
}

#Resources
resource "aws_instance" "mysqlexam" {
  ami           = "ami-0557a15b87f6559cf"
  instance_type = "t2.micro"
  tags = {
        Name = "mysqlexam"
  }
  vpc_security_group_ids = [aws_security_group.tf-sg.id]
  associate_public_ip_address = "true"
  key_name = "key2"
  subnet_id = aws_subnet.tf-subnet.id
  user_data = <<-EOF
   #!/bin/bash
   wget http://computing.utahtech.edu/it/3110/notes/2021/terraform/install.sh -O /tmp/install.sh
   chmod +x /tmp/install.sh
   source /tmp/install.sh
   EOF
}

#Resources
resource "aws_instance" "apacheexam" {
  ami           = "ami-0557a15b87f6559cf"
  instance_type = "t2.micro"
  tags = {
        Name = "apacheexam"
  }
  vpc_security_group_ids = [aws_security_group.tf-sg.id]
  associate_public_ip_address = "true"
  key_name = "key2"
  subnet_id = aws_subnet.tf-subnet.id
}

output "mysqlexam_ip_addr" {
        value = aws_instance.mysqlexam.public_ip
}
output "apacheexam_ip_addr" {
        value = aws_instance.apacheexam.public_ip
}
