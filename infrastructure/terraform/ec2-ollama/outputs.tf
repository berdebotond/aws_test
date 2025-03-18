output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.ollama_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.ollama_eip.public_ip
}

output "ollama_api_endpoint" {
  description = "Ollama API endpoint"
  value       = "http://${aws_eip.ollama_eip.public_ip}:11434"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh ec2-user@${aws_eip.ollama_eip.public_ip}"
} 