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

# Create a template for the user data script
locals {
  models_string = join(" ", var.ollama_models)
  user_data_template = <<-EOF
    #!/bin/bash
    
    # Setup logging
    exec > >(tee /var/log/user-data.log) 2>&1
    echo "Starting EC2 initialization script at $(date)"
    
    # Update system
    echo "Updating system packages..."
    yum update -y || {
      echo "Failed to update system packages"
      exit 1
    }
    
    # Install Docker
    echo "Installing Docker..."
    yum install -y docker || {
      echo "Failed to install Docker"
      exit 1
    }
    
    # Start Docker service
    echo "Starting Docker service..."
    systemctl start docker || {
      echo "Failed to start Docker service"
      exit 1
    }
    
    systemctl enable docker || {
      echo "Failed to enable Docker service"
      exit 1
    }
    
    usermod -aG docker ec2-user || {
      echo "Failed to add ec2-user to Docker group"
    }
    
    # Install Ollama
    echo "Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh || {
      echo "Failed to install Ollama"
      exit 1
    }
    
    # Create systemd service for Ollama
    echo "Creating Ollama service..."
    cat > /etc/systemd/system/ollama.service << 'SERVICEEOF'
    [Unit]
    Description=Ollama Service
    After=network.target
    
    [Service]
    Type=simple
    User=root
    ExecStart=/usr/local/bin/ollama serve
    Restart=always
    Environment="OLLAMA_HOST=0.0.0.0"
    
    [Install]
    WantedBy=multi-user.target
    SERVICEEOF
    
    # Reload systemd and start Ollama
    systemctl daemon-reload || {
      echo "Failed to reload systemd"
      exit 1
    }
    
    systemctl enable ollama || {
      echo "Failed to enable Ollama service"
      exit 1
    }
    
    systemctl start ollama || {
      echo "Failed to start Ollama service"
      exit 1
    }
    
    # Wait for Ollama service to be ready
    echo "Waiting for Ollama service to be ready..."
    for i in {1..30}; do
      if curl -s http://localhost:11434/api/tags >/dev/null; then
        echo "Ollama service is ready"
        break
      fi
      echo "Waiting for Ollama to start... ($i/30)"
      sleep 10
      if [ $i -eq 30 ]; then
        echo "Ollama service failed to start within timeout"
      fi
    done
    
    # Pull Ollama models
    echo "Pulling Ollama models: ${models_string}..."
    %{ for model in var.ollama_models ~}
    echo "Pulling ${model} model..."
    ollama pull ${model} || echo "Failed to pull ${model} model"
    %{ endfor ~}
    
    echo "EC2 initialization completed at $(date)"
  EOF
}

# EC2 instance
resource "aws_instance" "ollama_server" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t2.micro" # Free tier eligible
  key_name               = aws_key_pair.ollama_key.key_name
  vpc_security_group_ids = [aws_security_group.ollama_sg.id]
  
  user_data = templatefile("${path.module}/userdata.tpl", {
    environment = var.environment,
    models_string = local.models_string,
    ollama_models = var.ollama_models
  })
  
  # Alternative if you don't want to use a separate template file
  # user_data = local.user_data_template
  
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