terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "eu-central-1" # Europe (Frankfurt)
}

# Get latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security group for Ollama
resource "aws_security_group" "ollama_sg" {
  name        = "${var.environment}-ollama-sg"
  description = "Security group for Ollama server"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }
  
  # Ollama API
  ingress {
    from_port   = 11434
    to_port     = 11434
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Ollama API access"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-ollama-sg"
    Environment = var.environment
  }
}

# Create SSH key pair for EC2 access
resource "aws_key_pair" "ollama_key" {
  key_name   = "${var.environment}-ollama-key"
  public_key = file(var.ssh_public_key_path)
}

# EC2 instance
resource "aws_instance" "ollama_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro" # Free tier eligible
  key_name               = aws_key_pair.ollama_key.key_name
  vpc_security_group_ids = [aws_security_group.ollama_sg.id]
  
  # Use the userdata.tpl file for user_data
  user_data = templatefile("${path.module}/userdata.tpl", {
    environment   = var.environment,
    models_string = join(" ", var.ollama_models),
    ollama_models = var.ollama_models
  })
  
  tags = {
    Name        = "${var.environment}-ollama-server"
    Environment = var.environment
  }
  
  volume_tags = {
    Name        = "${var.environment}-ollama-server"
    Environment = var.environment
  }
}

# Create Elastic IP for the EC2 instance
resource "aws_eip" "ollama_eip" {
  instance = aws_instance.ollama_server.id
  domain   = "vpc"
  
  tags = {
    Name        = "${var.environment}-ollama-eip"
    Environment = var.environment
  }
} 