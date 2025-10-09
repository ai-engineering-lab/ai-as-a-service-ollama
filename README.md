# Terra-Ollama-Phi 🚀

A Terraform infrastructure-as-code project that automatically provisions an AWS EC2 instance running **Ollama** with **Phi-4-Mini (phi4-mini:3.8b)** for cloud-based AI inference.

(Previously defaulted to Gemma2:9b.)


## 📋 Project Overview

This project creates a production-ready AI inference server on AWS that:
- Automatically installs and configures Ollama
- Downloads and serves the Phi-4-Mini model
- Restricts access to your specific IP address
- Provides a professional systemd service setup
- Includes comprehensive testing tools

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌────────────────────────┐
│   Your Local    │───▶│   AWS EC2        │───▶│   Ollama + Phi-4-Mini  │
│   Machine       │    │   (t2.xlarge)    │    │   Port: 11434          │
│   (Your IP)     │    │   (Dynamic IP)   │    │                        │
└─────────────────┘    └──────────────────┘    └────────────────────────┘
```

## 🛠️ Prerequisites

(Identical to previous version: AWS CLI, Terraform, SSH key, your public IP.)

## 🔐 Configuration Setup

Use `terraform.tfvars` and optionally `credentials.env` (from `credentials.template`).  
Model now: `phi4-mini:3.8b`.

## 🚀 Quick Start

```bash
terraform init
terraform apply -auto-approve
```

The instance will:
- Install Ollama
- Pull `phi4-mini:3.8b`
- Register a systemd service
- Expose API on port 11434 (restricted by security group)

## 🧪 Testing & Interaction

### Test Script
```bash
./test-ollama-phi.sh
```

### Simple Chat (Shell)
```bash
./phi-chat.sh
```

### Advanced Python Interactive
```bash
./setup_python_env.sh --venv
python3 phi_interactive.py -H <EC2_PUBLIC_IP>
```

## 📁 Project Structure

```
.
├── main.tf
├── terraform.tfvars.example
├── test-ollama-phi.sh
├── phi-chat.sh
├── phi_interactive.py
├── setup_python_env.sh
├── requirements.txt
├── credentials.template
├── README.md
└── .gitignore
```

## 🔧 Key Terraform Behavior (main.tf)

- EC2 `t2.xlarge`
- Security group restricts SSH (22) + Ollama (11434) to `allowed_ip`
- User data installs Ollama + pulls `phi4-mini:3.8b`

## 🔍 API Usage Examples

Basic:
```bash
curl -X POST http://<EC2_IP>:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d '{"model": "phi4-mini:3.8b", "prompt": "Hello!"}'
```

Streaming:
```bash
curl -X POST http://<EC2_IP>:11434/api/generate \
  -H 'Content-Type: application/json' \
  -d '{"model":"phi4-mini:3.8b","prompt":"Tell me a short story","stream":true}'
```

List models:
```bash
curl http://<EC2_IP>:11434/api/tags
```

## 🐍 Python Interactive Features

(Identical features: history, save/load, model switching, streaming toggle.)

Run:
```bash
python3 phi_interactive.py -m phi4-mini:3.8b
```

## 🔒 Security

- IP whitelisting
- Non-root service user
- Systemd management
- Auto-restart

## 🛠️ Troubleshooting

Check service:
```bash
ssh -i YourKey.pem ubuntu@<EC2_IP> "systemctl status ollama"
```

Check model available:
```bash
ssh -i YourKey.pem ubuntu@<EC2_IP> "sudo -u ollama ollama list"
```

Pull manually:
```bash
ssh -i YourKey.pem ubuntu@<EC2_IP> "sudo -u ollama ollama pull phi4-mini:3.8b"
```

## 📊 Model & Performance Notes

- Model: Phi-4-Mini `phi4-mini:3.8b`
- Smaller footprint vs Gemma2:9b
- Faster load and lower RAM usage (beneficial on t2.xlarge)

## 🧹 Cleanup

```bash
terraform destroy
```

---

Switched default model & scripts from Gemma2:9b to Phi-4-Mini (phi4-mini:3.8b).