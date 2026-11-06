terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # Change to your preferred region
}

resource "aws_instance" "demo_server" {
  ami           = "ami-0c7217cdde317cfec" # Replace with a valid Ubuntu or Amazon Linux AMI ID for your region
  instance_type = "t2.micro"             # Free-tier eligible

  tags = {
    Name = "Terraform-Demo-Instance"
  }
}