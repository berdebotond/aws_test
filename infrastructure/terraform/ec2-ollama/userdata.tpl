#!/bin/bash

# Setup logging
exec > >(tee /var/log/user-data.log) 2>&1
echo "Starting EC2 initialization script for ${environment} environment at $(date)"

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
%{ for model in ollama_models ~}
echo "Pulling ${model} model..."
ollama pull ${model} || echo "Failed to pull ${model} model"
%{ endfor ~}

# Setup complete banner
cat > /etc/motd << 'MOTDEOF'
=======================================================
 _____  _  _                           
|  _  || || |                          
| | | || || | __ _  _ __ ___    __ _   
| | | || || |/ _' || '_ ' _ \  / _' |  
\ \_/ /| || | (_| || | | | | || (_| |  
 \___/ |_||_|\__,_||_| |_| |_| \__,_|  
=======================================================
Environment: ${environment}
API Endpoint: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):11434
Available Models: ${models_string}
=======================================================
MOTDEOF

echo "EC2 initialization completed at $(date)" 