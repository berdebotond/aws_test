variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key for EC2 instance access"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "ollama_models" {
  description = "List of Ollama models to pull at startup"
  type        = list(string)
  default     = ["llama2"]
} 