#!/bin/bash

# Script to deploy Ollama EC2 instance

# Default values
ENVIRONMENT="dev"
SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"
MODELS="llama2"

# Help function
function show_help {
  echo "Usage: $0 [OPTIONS]"
  echo "Deploy an EC2 instance with Ollama in the Frankfurt region"
  echo ""
  echo "Options:"
  echo "  -e, --environment ENV     Environment to deploy (dev, staging, prod)"
  echo "  -k, --key-path PATH       Path to SSH public key"
  echo "  -m, --models MODELS       Comma-separated list of Ollama models to pull"
  echo "  -h, --help                Show this help message"
  echo ""
  echo "Example:"
  echo "  $0 -e prod -k ~/.ssh/ollama_key.pub -m llama2,mistral"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -e|--environment)
      ENVIRONMENT="$2"
      shift 2
      ;;
    -k|--key-path)
      SSH_KEY_PATH="$2"
      shift 2
      ;;
    -m|--models)
      MODELS="$2"
      shift 2
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
  echo "Error: Environment must be one of: dev, staging, prod"
  exit 1
fi

# Check if SSH key exists
if [ ! -f "$SSH_KEY_PATH" ]; then
  echo "Error: SSH public key not found at $SSH_KEY_PATH"
  echo "Would you like to generate a new SSH key? (y/n)"
  read -r generate_key
  
  if [[ "$generate_key" =~ ^[Yy]$ ]]; then
    echo "Generating new SSH key at $SSH_KEY_PATH..."
    ssh-keygen -t rsa -b 2048 -f "${SSH_KEY_PATH%.pub}" -N ""
  else
    exit 1
  fi
fi

# Format models for Terraform
IFS=',' read -ra MODEL_ARRAY <<< "$MODELS"
MODEL_LIST="["
for model in "${MODEL_ARRAY[@]}"; do
  MODEL_LIST+="\"$model\","
done
MODEL_LIST="${MODEL_LIST%,}]"

echo "Deploying Ollama EC2 instance..."
echo "Environment: $ENVIRONMENT"
echo "SSH Key: $SSH_KEY_PATH"
echo "Models: $MODELS"

# Initialize Terraform
terraform init

# Apply Terraform configuration
terraform apply \
  -var="environment=$ENVIRONMENT" \
  -var="ssh_public_key_path=$SSH_KEY_PATH" \
  -var="ollama_models=$MODEL_LIST" \
  -auto-approve

# Get outputs
INSTANCE_IP=$(terraform output -raw instance_public_ip)
OLLAMA_API=$(terraform output -raw ollama_api_endpoint)

echo ""
echo "Deployment complete!"
echo "Ollama API endpoint: $OLLAMA_API"
echo "SSH command: ssh ec2-user@$INSTANCE_IP"
echo ""
echo "Note: It may take a few minutes for Ollama to fully initialize and download models."
echo "To check the status, SSH into the instance and run: sudo systemctl status ollama" 