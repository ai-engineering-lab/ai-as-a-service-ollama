###############################################
# TERRAFORM to build EC2-OLLAMA with Phi Mini
#
# Region: ca-central-1 (Canada Central)
# Base: Original Gemma version (modified for phi4-mini:3.8b)
# Notes:
#  - Removed awscli from packages (breaks on Ubuntu 24.04 default repos)
#  - Smaller instance & disk (adjust as needed)
###############################################

provider "aws" {
  region = "ca-central-1"
}

# Variables for sensitive / overridable configuration
variable "ssh_key_name" {
  description = "Name of the SSH key pair to use for EC2 instance"
  type        = string
  default     = "your-ssh-key-name"
}

variable "allowed_ip" {
  description = "IP address allowed to access the instance (CIDR format)"
  type        = string
  # IMPORTANT: change this to your public IP with /32, e.g. "144.172.xxx.xxx/32"
  default = "0.0.0.0/0"
}

# Security Group allowing only your IP
resource "aws_security_group" "ollama_sg" {
  name        = "ollama-security-group"
  description = "Security group for Ollama instance - restricted to current IP"

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
    description = "SSH access from allowed IP"
  }

  # Ollama API
  ingress {
    from_port   = 11434
    to_port     = 11434
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
    description = "Ollama service access from allowed IP"
  }

  # All outbound
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
  ami                    = "ami-0dd67d541aa70c8b9" # Ubuntu 24.04 LTS (static)
  instance_type          = "t3.large"              # Smaller than t2.xlarge; adjust as needed
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.ollama_sg.id]

  # Root volume (phi4-mini doesn't need 100GB; 50GB is roomy)
  ebs_block_device {
    device_name           = "/dev/sda1"
    volume_size           = 50
    delete_on_termination = true
  }

  #################################################################
  # Generate your PEM for key_name (example):
  # aws ec2 create-key-pair --key-name YourKeyName \
  #   --query 'KeyMaterial' --output text > YourKeyName.pem
  #################################################################

  user_data = <<-EOF
              #!/bin/bash
              set -euo pipefail

              LOG_FILE=/var/log/ollama-setup.log
              exec > >(tee -a "$LOG_FILE") 2>&1

              echo "[1/8] Update system packages"
              apt-get update
              apt-get -y upgrade

              echo "[2/8] Install required packages (no awscli here)"
              # Removed awscli to avoid failure on Ubuntu 24.04
              apt-get install -y gnupg software-properties-common unzip curl

              echo "[3/8] Install Ollama"
              curl -fsSL https://ollama.com/install.sh | sh

              echo "[4/8] Create ollama user (idempotent) and directories"
              id ollama 2>/dev/null || useradd -r -s /bin/false -m -d /usr/share/ollama ollama
              mkdir -p /usr/share/ollama/.ollama
              chown -R ollama:ollama /usr/share/ollama/.ollama

              echo "[5/8] Create systemd service"
              tee /etc/systemd/system/ollama.service > /dev/null <<EOL
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

              echo "[6/8] Enable and start Ollama"
              systemctl daemon-reload
              systemctl enable ollama
              systemctl start ollama

              echo "[7/8] Wait for service to settle"
              sleep 20

              echo "[8/8] Pull phi model (phi4-mini:3.8b)"
              sudo -u ollama ollama pull phi4-mini:3.8b || echo "Model pull attempt finished (non-fatal if failed)"

              echo "----- SUMMARY -----" >> "$LOG_FILE"
              echo "Service status: $(systemctl is-active ollama)" >> "$LOG_FILE"
              echo "Available models: $(sudo -u ollama ollama list || true)" >> "$LOG_FILE"
              echo "Setup complete for phi4-mini:3.8b" >> "$LOG_FILE"
              EOF

  tags = {
    Name  = "terraform-ollama-1456"
    Model = "phi4-mini:3.8b"
  }
}