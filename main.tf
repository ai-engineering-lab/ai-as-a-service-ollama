
###############################################
# TERRAFORM to build EC2-OLLAMA with Gemma AI
#
# Region: ca-central-1 (Canada Central)
# Designer: Dang Hoang, AI Eng.
#

provider "aws" {
  region = "ca-central-1"
}

# Variables for sensitive configuration
variable "ssh_key_name" {
  description = "Name of the SSH key pair to use for EC2 instance"
  type        = string
  default     = "your-ssh-key-name"
}

variable "allowed_ip" {
  description = "IP address allowed to access the instance (CIDR format)"
  type        = string
  default     = "0.0.0.0/0"  # Change this to your IP
}

# Custom security group allowing access only from your current IP
resource "aws_security_group" "ollama_sg" {
  name        = "ollama-security-group"
  description = "Security group for Ollama instance - restricted to current IP"
  
  # Allow SSH access from your IP
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
    description = "SSH access from allowed IP"
  }
  
  # Allow Ollama service access from your IP
  ingress {
    from_port   = 11434
    to_port     = 11434
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
    description = "Ollama service access from allowed IP"
  }
  
  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "ollama-security-group"
  }
}

resource "aws_instance" "terraform-ollama-1456" {
  ami                    = "ami-0dd67d541aa70c8b9"  # Ubuntu 24.04 LTS
  instance_type          = "t2.xlarge"
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.ollama_sg.id]

  ebs_block_device {
    device_name           = "/dev/sda1" // This is typically the root volume
    volume_size           = 100          // Set the volume size to 100GB
    delete_on_termination = true         // Ensure the volume is deleted when the instance is terminated
  }


  #################################################################
  ########### Generate your PEM for key_name ######################
  #aws ec2 create-key-pair --key-name YourKeyName --query 'KeyMaterial' --output text > YourKeyName.pem
  #################################################################

  user_data = <<-EOF
              #!/bin/bash

              # Update system packages
              sudo apt-get update
              sudo apt -y upgrade

              # Install required packages
              sudo apt-get install -y gnupg software-properties-common awscli unzip curl

              # Install Ollama
              curl -fsSL https://ollama.com/install.sh | sh

              # Create ollama user and set up service
              sudo useradd -r -s /bin/false -m -d /usr/share/ollama ollama
              sudo mkdir -p /usr/share/ollama/.ollama
              sudo chown -R ollama:ollama /usr/share/ollama

              # Create systemd service for Ollama
              sudo tee /etc/systemd/system/ollama.service > /dev/null <<EOL
              [Unit]
              Description=Ollama Service
              After=network-online.target

              [Service]
              ExecStart=/usr/local/bin/ollama serve
              User=ollama
              Group=ollama
              Restart=always
              RestartSec=3
              Environment="PATH=/usr/local/bin:/usr/bin:/bin"
              Environment="OLLAMA_HOST=0.0.0.0:11434"

              [Install]
              WantedBy=default.target
              EOL

              # Enable and start Ollama service
              sudo systemctl daemon-reload
              sudo systemctl enable ollama
              sudo systemctl start ollama

              # Wait for Ollama service to be ready
              sleep 30

              # Pull the latest Gemma model (using gemma2:9b as it's a good balance of performance/size)
              sudo -u ollama ollama pull gemma2:9b

              # Optional: Pull additional Gemma variants if needed
              # sudo -u ollama ollama pull gemma2:2b    # Smaller, faster model
              # sudo -u ollama ollama pull gemma2:27b   # Larger, more capable model

              # Log completion
              echo "Ollama service started with Gemma2:9b model" >> /var/log/ollama-setup.log
              echo "Service status: $(systemctl is-active ollama)" >> /var/log/ollama-setup.log
              echo "Available models: $(sudo -u ollama ollama list)" >> /var/log/ollama-setup.log

              EOF

  tags = {
    Name = "terraform-ollama-1456"
  }


}
