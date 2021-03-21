terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
  backend "s3" {
    bucket = "walle-terraform"
    key    = "terraform-state"
    region = "us-east-2"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-2"
  shared_credentials_file = "/Users/erik/.aws/credentials"
}

# Create a VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-2c"

  tags = {
    Name = "tf-example"
  }
}

resource "aws_network_interface" "interface" {
  subnet_id   = aws_subnet.main.id
  private_ips = ["10.0.10.100"]

  tags = {
    Name = "primary_network_interface"
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "main" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.interface.id
    device_index         = 0
  }

}
