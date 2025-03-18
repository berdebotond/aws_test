# Ollama EC2 Instance in Frankfurt (eu-central-1)

This Terraform configuration sets up an EC2 instance in the Frankfurt region with Ollama pre-installed.

## Features

- Deploys a free tier eligible t2.micro EC2 instance in the eu-central-1 region
- Automatically installs and configures Ollama
- Creates security groups for SSH and Ollama API access
- Assigns an Elastic IP for a static public IP address
- Configures for different environments (dev, staging, prod)

## Requirements

- AWS account with appropriate permissions
- Terraform installed locally
- SSH key for EC2 access

## Usage

### Local Deployment

1. Generate an SSH key if you don't have one:
   ```bash
   ssh-keygen -t rsa -b 2048 -f ~/.ssh/ollama_key
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Deploy for development:
   ```bash
   terraform apply -var="environment=dev" -var="ssh_public_key_path=~/.ssh/ollama_key.pub"
   ```

   Or for production:
   ```bash
   terraform apply -var="environment=prod" -var="ssh_public_key_path=~/.ssh/ollama_key.pub"
   ```

4. After deployment, you can access:
   - Ollama API at `http://<public_ip>:11434`
   - SSH into the instance with `ssh ec2-user@<public_ip>`

### CI/CD Deployment

The repository includes GitHub Actions workflows that will:

- Deploy to development environments for feature branches
- Deploy to production for the main branch
- Perform Terraform validation on pull requests

## Variables

| Name | Description | Default |
|------|-------------|---------|
| environment | Environment (dev, staging, prod) | dev |
| ssh_public_key_path | Path to SSH public key | ~/.ssh/id_rsa.pub |
| ollama_models | List of Ollama models to pull | ["llama2"] |

## Outputs

| Name | Description |
|------|-------------|
| instance_id | ID of the EC2 instance |
| instance_public_ip | Public IP of the instance |
| ollama_api_endpoint | URL for the Ollama API |
| ssh_command | SSH command to connect to the instance |

## Notes

- This setup is designed to work with AWS free tier
- The EC2 instance is configured with a t2.micro instance type
- The Ollama API is publicly accessible (port 11434) 