# Terra-Ollama-Gemma 🚀

A Terraform infrastructure-as-code project that automatically provisions an AWS EC2 instance running **Ollama** with **Google's Gemma2:9b** AI model for cloud-based AI inference.

**Dang Hoang, AI Eng.** - Project Designer and Developer

## 📋 Project Overview

This project creates a production-ready AI inference server on AWS that:
- Automatically installs and configures Ollama
- Downloads and serves the Gemma2:9b model
- Restricts access to your specific IP address
- Provides a professional systemd service setup
- Includes comprehensive testing tools

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Your Local    │───▶│   AWS EC2        │───▶│   Ollama +      │
│   Machine       │    │   (t2.xlarge)    │    │   Gemma2:9b     │
│   (Your IP)     │    │   (Dynamic IP)   │    │   Port: 11434   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 🛠️ Prerequisites

- **AWS CLI** configured with appropriate credentials
- **Terraform** (v1.5.7 or later)
- **SSH Key Pair** in your AWS account
- **Your Public IP** (will be configured in terraform.tfvars)

## 🔐 Configuration Setup

### Required AWS Permissions
Your AWS credentials need the following permissions:
- `ec2:RunInstances`
- `ec2:CreateSecurityGroup`
- `ec2:AuthorizeSecurityGroupIngress`
- `ec2:AuthorizeSecurityGroupEgress`
- `ec2:DescribeInstances`
- `ec2:DescribeSecurityGroups`
- `ec2:DescribeImages`
- `ec2:DescribeKeyPairs`

### AWS CLI Setup
```bash
# Configure AWS CLI (if not already done)
aws configure

# Verify your credentials
aws sts get-caller-identity
```

### Terraform Variables Configuration
```bash
# Copy the example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit with your actual values
nano terraform.tfvars
```

**Required variables in `terraform.tfvars`:**
```hcl
ssh_key_name = "your-actual-ssh-key-name"
allowed_ip   = "YOUR_PUBLIC_IP/32"  # e.g., "203.0.113.1/32"
```

### Environment Variables (Optional)
For easier management, you can use the provided credentials template:
```bash
# Copy and customize the credentials template
cp credentials.template credentials.env

# Edit with your actual values
nano credentials.env

# Source the environment variables
source credentials.env
```

## 🚀 Quick Start

### 1. Clone and Navigate
```bash
git clone <your-repo-url>
cd terra-ollama-1
```

### 2. Deploy Infrastructure
```bash
terraform init
terraform plan
terraform apply -auto-approve
```

### 3. Wait for Initialization
The instance will automatically:
- Install Ollama
- Download Gemma2:9b model (~5.4GB)
- Configure systemd service
- Start the AI inference server

**Initialization time**: ~5-10 minutes

### 4. Test Your Deployment
```bash
# Run comprehensive test suite
./test-ollama-gemma.sh

# Start interactive chat
./gemma-chat.sh
```

## 📁 Project Structure

```
terra-ollama-1/
├── main.tf                    # Main Terraform configuration
├── terraform.tfstate          # Terraform state file
├── terraform.tfstate.backup   # Backup state file
├── test-ollama-gemma.sh       # Comprehensive test suite
├── gemma-chat.sh             # Interactive chat interface
├── README.md                 # This file
└── .terraform/               # Terraform provider cache
```

## 🔧 Configuration Details

### AWS Resources Created

| Resource | Type | Details |
|----------|------|---------|
| **EC2 Instance** | `t2.xlarge` | Ubuntu 24.04 LTS, 4 vCPUs, 16GB RAM |
| **EBS Volume** | `100GB gp3` | Auto-deleted on termination |
| **Security Group** | `ollama-security-group` | IP-restricted (SSH + Ollama) |
| **Public IP** | Dynamic | `15.222.244.108` (current) |

### Security Configuration

- **SSH Access**: Port 22 (restricted to your IP)
- **Ollama Service**: Port 11434 (restricted to your IP)
- **Outbound Traffic**: All allowed
- **IP Whitelist**: `50.98.231.234/32`

### Model Information

- **Model**: `gemma2:9b`
- **Size**: ~5.4GB
- **Parameters**: 9.2B
- **Quantization**: Q4_0
- **Format**: GGUF

## 🧪 Testing & Usage

### API Testing
```bash
# Simple test
curl -X POST http://15.222.244.108:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d '{"model": "gemma2:9b", "prompt": "Hello, how are you?"}'

# Check available models
curl http://15.222.244.108:11434/api/tags
```

### Interactive Chat
```bash
./gemma-chat.sh
```

### SSH Access
```bash
ssh -i YourKeyName3.pem ubuntu@15.222.244.108
```

## 🔍 Monitoring & Management

### Service Status
```bash
# Check Ollama service status
ssh -i YourKeyName3.pem ubuntu@15.222.244.108 "systemctl status ollama"

# View service logs
ssh -i YourKeyName3.pem ubuntu@15.222.244.108 "journalctl -u ollama -f"
```

### Setup Logs
```bash
# View initialization logs
ssh -i YourKeyName3.pem ubuntu@15.222.244.108 "cat /var/log/ollama-setup.log"
```

## 💰 Cost Estimation

| Resource | Cost (USD/month) |
|----------|------------------|
| **t2.xlarge** | ~$150-200 |
| **100GB EBS** | ~$10 |
| **Data Transfer** | Variable |
| **Total** | ~$160-210/month |

*Costs may vary by region and usage patterns*

## 🔒 Security Features

- ✅ **IP Whitelisting**: Only your IP can access the service
- ✅ **Non-root Service**: Ollama runs as dedicated user
- ✅ **Systemd Integration**: Professional service management
- ✅ **Auto-restart**: Service automatically recovers from failures
- ✅ **Encrypted Storage**: EBS volumes support encryption

## 🛠️ Troubleshooting

### Common Issues

**Service Not Responding**
```bash
# Check if Ollama is running
curl http://15.222.244.108:11434/api/tags

# SSH and check service status
ssh -i YourKeyName3.pem ubuntu@15.222.244.108 "systemctl status ollama"
```

**Model Not Available**
```bash
# Check if model is downloaded
ssh -i YourKeyName3.pem ubuntu@15.222.244.108 "sudo -u ollama ollama list"

# Manually pull model if needed
ssh -i YourKeyName3.pem ubuntu@15.222.244.108 "sudo -u ollama ollama pull gemma2:9b"
```

**IP Access Issues**
- Verify your current public IP: `curl ifconfig.me`
- Update security group if IP changed
- Check AWS console for security group rules

## 🔄 Maintenance

### Updating IP Address
If your IP changes, update the security group:
```bash
# Update main.tf with new IP
# Then apply changes
terraform apply
```

### Scaling Resources
To change instance type:
```bash
# Edit main.tf (instance_type)
# Apply changes
terraform apply
```

### Cleanup
To destroy all resources:
```bash
terraform destroy
```

## 📊 Performance Metrics

- **Response Time**: ~4-5 seconds for typical queries
- **Concurrent Requests**: Limited by t2.xlarge capacity
- **Model Loading**: ~30 seconds on first request
- **Memory Usage**: ~8-10GB for Gemma2:9b

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

**🎯 Ready to deploy AI inference in the cloud!**
